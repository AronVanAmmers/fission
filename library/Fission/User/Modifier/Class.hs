module Fission.User.Modifier.Class
  ( Modifier (..)
  , Errors
  ) where

import           Database.Persist as Persist
import           Servant.Server

import qualified Network.IPFS.Add.Error as IPFS.Pin
import qualified Network.IPFS.Get.Error as IPFS.Stat
import           Network.IPFS.CID.Types

import           Fission.Error
import           Fission.Models
import           Fission.Prelude

import           Fission.Key           as Key
import           Fission.URL
import           Fission.User.Password as Password

type Errors = OpenUnion
  '[ NotFound User
  
   , NotFound            URL
   , ActionNotAuthorized URL

   , IPFS.Pin.Error
   , IPFS.Stat.Error

   , ServerError
   , InvalidURL
   ]

class Monad m => Modifier m where
  updatePassword ::
       UserId
    -> Password
    -> UTCTime
    -> m (Either Password.FailedDigest Password)

  updatePublicKey ::
       UserId
    -> Key.Public
    -> UTCTime
    -> m (Either Errors Key.Public)
   
  setData ::
       UserId
    -> CID
    -> Natural
    -> UTCTime
    -> m (Either Errors ())

instance MonadIO m => Modifier (Transaction m) where
  updatePassword userId password now =
    Password.hashPassword password >>= \case
      Left err ->
        return (Left err)

      Right secretDigest -> do
        update userId
          [ UserSecretDigest =. Just secretDigest
          , UserModifiedAt   =. now
          ]

        return (Right password)

  updatePublicKey userID pk now = do
    update userID
      [ UserPublicKey  =. Just pk
      , UserModifiedAt =. now
      ]

    return $ Right pk

  setData userId newCID size now = do
    update userId
      [ UserDataRoot     =. newCID
      , UserDataRootSize =. size
      , UserModifiedAt   =. now
      ]

    insert_ UpdateUserDataRootEvent
      { updateUserDataRootEventUserId      = userId
      , updateUserDataRootEventNewDataRoot = newCID
      , updateUserDataRootEventInsertedAt  = now
      }

    return ok

