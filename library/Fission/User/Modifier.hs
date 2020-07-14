module Fission.User.Modifier
  ( updatePasswordDB
  , updatePublicKeyDB
  , setDataDB
  , module Fission.User.Modifier.Class
  ) where

import Fission.User.Modifier.Class

import           Database.Persist as Persist

import           Network.IPFS.CID.Types
import           Network.IPFS.Bytes.Types

import           Fission.Models
import           Fission.Prelude

import           Fission.Key           as Key
import           Fission.Security.Types

updatePasswordDB ::
     MonadIO m
  => UserId
  -> SecretDigest
  -> UTCTime
  -> Transaction m ()
updatePasswordDB userId secretDigest now =
  update userId
    [ UserSecretDigest =. Just secretDigest
    , UserModifiedAt   =. now
    ]

updatePublicKeyDB ::
     MonadIO m
  => UserId
  -> Key.Public
  -> UTCTime
  -> Transaction m ()
updatePublicKeyDB userID pk now =
  update userID
    [ UserPublicKey  =. Just pk
    , UserModifiedAt =. now
    ]
  
setDataDB ::
     MonadIO m
  => UserId
  -> CID
  -> Bytes
  -> UTCTime
  -> Transaction m ()
setDataDB userId newCID size now = do
  update userId
    [ UserDataRoot     =. newCID
    , UserDataRootSize =. size
    , UserModifiedAt   =. now
    ]

  insert_ $ UpdateUserDataRootEvent userId newCID size now
