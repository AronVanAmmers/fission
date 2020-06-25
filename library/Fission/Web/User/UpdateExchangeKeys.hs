module Fission.Web.User.UpdateExchangeKeys
  ( API
  , server
  ) where

import           Servant

import           Fission.Prelude
import           Fission.Authorization
 
import qualified Fission.Web.Error as Web.Error

import qualified Crypto.PubKey.RSA as RSA
import qualified Fission.User      as User

type API
  =  Summary "Update Public Exchange Keys"
  :> Description "Set currently authenticated user's root list of public exchange keys"
  :> ReqBody '[JSON] [RSA.PublicKey]
  :> Put     '[PlainText, OctetStream, JSON] NoContent

server ::
  ( MonadTime     m
  , MonadLogger   m
  , MonadThrow    m
  , User.Modifier m
  )
  => Authorization
  -> ServerT API m
server Authorization {about = Entity userID _} keys = do
  now <- currentTime
  Web.Error.ensureM $ User.updateExchangeKeys userID keys now
  return NoContent
