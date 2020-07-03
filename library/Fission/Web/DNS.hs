module Fission.Web.DNS
  ( API
  , server
  ) where

import           Database.Esqueleto
import           Servant

import           Fission.Authorization
import           Fission.Models
import           Fission.Prelude

import           Fission.URL                 as URL
import           Fission.Web.Error           as Web.Err

import           Fission.User.Username.Types
import qualified Fission.User.Modifier       as User

import qualified Network.IPFS.Stat as IPFS.Stat
import           Network.IPFS.CID.Types
import           Network.IPFS.Remote.Class

type API
  =  Summary "Set account's DNSLink"
  :> Description "DEPRECATED ⛔ Set account's DNSLink to a CID"
  :> Capture "cid" CID
  :> PutAccepted '[PlainText, OctetStream] DomainName

-- Deprecated! Works the "old" way with direct access to username.fission.name,
-- WITHOUT the `files` prefix
server ::
  ( MonadTime     m
  , MonadThrow    m
  , MonadLogger   m
  , MonadRemoteIPFS m
  , User.Modifier m
  )
  => Authorization -> ServerT API m
server Authorization {about = Entity userID User {userUsername = Username rawUN}} cid = do
  now <- currentTime
  stat <- Web.Err.ensureM $ IPFS.Stat.getStatRemote cid
  let size = IPFS.Stat.cumulativeSize stat
  ensureM $ User.setData userID cid size now
  return . DomainName $ rawUN <> ".fission.name"
