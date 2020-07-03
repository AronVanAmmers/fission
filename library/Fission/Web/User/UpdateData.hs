module Fission.Web.User.UpdateData
  ( API
  , server
  ) where

import           Database.Esqueleto
import           Servant

import           Fission.Prelude
import           Fission.Authorization

import           Fission.Web.Error as Web.Error
import qualified Fission.User as User

import qualified Network.IPFS.Stat as IPFS.Stat
import           Network.IPFS.CID.Types
import           Network.IPFS.Remote.Class


type API
  =  Summary "Update data root"
  :> Description "Set/update currently authenticated user's file system content"
  :> Capture "newCID" CID
  :> PatchNoContent '[PlainText, OctetStream, JSON] NoContent

server ::
  ( MonadLogger   m
  , MonadThrow    m
  , MonadTime     m
  , MonadRemoteIPFS m
  , User.Modifier m
  )
  => Authorization
  -> ServerT API m
server Authorization {about = Entity userID _} newCID = do
  now <- currentTime
  stat <- Web.Error.ensureM $ IPFS.Stat.getStatRemote newCID
  let size = IPFS.Stat.cumulativeSize stat
  Web.Error.ensureM $ User.setData userID newCID size now
  return NoContent
