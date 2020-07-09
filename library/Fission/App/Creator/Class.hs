module Fission.App.Creator.Class
  ( Creator (..)
  , Errors
  ) where

import           Database.Esqueleto hiding ((<&>))
import           Servant

import           Network.IPFS.CID.Types
import           Network.IPFS.Bytes.Types

import           Fission.Prelude
import           Fission.Error as Error
import           Fission.Models
import           Fission.URL

import qualified Fission.App.Domain as App.Domain

type Errors = OpenUnion
  '[ ServerError
   , App.Domain.AlreadyAssociated

   , ActionNotAuthorized App
   , NotFound            App

   , ActionNotAuthorized URL
   , NotFound            URL

   , InvalidURL
   ]

class Monad m => Creator m where
  create :: 
       UserId 
    -> CID 
    -> Bytes 
    -> UTCTime 
    -> m (Either Errors (AppId, Subdomain))

instance (MonadIO m, App.Domain.Initializer m) => Creator (Transaction m) where
  create ownerId cid size now = do
    appId <- insert App
      { appOwnerId    = ownerId
      , appCid        = cid
      , appSize       = size
      , appInsertedAt = now
      , appModifiedAt = now
      }

    _ <- insert $ CreateAppEvent appId ownerId cid size now

    App.Domain.associateDefault ownerId appId now <&> \case
      Left  err       -> Error.relaxedLeft err
      Right subdomain -> Right (appId, subdomain)
