module Fission.Web.App.Update
  ( API
  , update
  ) where

import           Servant

import           Network.IPFS.CID.Types

import           Fission.Authorization
import           Fission.Prelude

import qualified Fission.App            as App
import           Fission.Web.Error      as Web.Error

import           Fission.URL.Types

import qualified Network.IPFS.Stat as IPFS.Stat
import           Network.IPFS.Remote.Class


type API
  =  Summary     "Set app content"
  :> Description "Update the content (CID) for an app"
  :> Capture     "App URL" URL
  :> Capture     "New CID" CID
  :> QueryParam  "copy-data" Bool
  :> PatchAccepted '[JSON] NoContent

update ::
  ( MonadLogger     m
  , MonadThrow      m
  , MonadTime       m
  , MonadRemoteIPFS m
  , App.Modifier    m
  )
  => Authorization
  -> ServerT API m
update Authorization {about = Entity userId _} url newCID copyDataFlag = do
  now <- currentTime
  size <- Web.Error.ensureM $ IPFS.Stat.getSizeRemote newCID
  Web.Error.ensureM $ App.setCID userId url newCID size copyFiles now
  return NoContent
  where
    copyFiles :: Bool
    copyFiles = maybe True identity copyDataFlag
