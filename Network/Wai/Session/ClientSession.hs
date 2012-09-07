module Network.Wai.Session.ClientSession (clientsessionStore) where

import Control.Monad
import Data.ByteString (ByteString)
import Control.Monad.IO.Class (liftIO, MonadIO)
import Network.Wai.Session (Session, SessionStore)
import Data.IORef
import Control.Error (hush)

import Web.ClientSession (Key, encryptIO, decrypt)
import Data.Serialize (encode, decode, Serialize) -- Use cereal because clientsession does

-- | Session store that keeps all content in a 'Serialize'd cookie encrypted
-- with 'Web.ClientSession'
--
-- WARNING: This session is vulnerable to sidejacking,
-- use with TLS for security.
clientsessionStore :: (Serialize k, Serialize v, Eq k, MonadIO m) => Key -> SessionStore m k v
clientsessionStore cryptKey (Just encoded) =
	case hush . decode =<< decrypt cryptKey encoded of
		Just sessionData -> backend cryptKey sessionData
		-- Bad cookie is the same as no cookie
		Nothing -> clientsessionStore cryptKey Nothing
clientsessionStore cryptKey Nothing = backend cryptKey []

backend :: (Serialize k, Serialize v, Eq k, MonadIO m) => Key -> [(k, v)] -> IO (Session m k v, IO ByteString)
backend cryptKey sessionData = do
	-- Don't need threadsafety because we only hand this IORef to an Application
	-- through a single Request.
	ref <- newIORef sessionData
	return ((
			(\k -> lookup k `liftM` liftIO (readIORef ref)),
			(\k v -> liftIO (modifyIORef ref (((k,v):) . filter ((/=k) . fst))))
		), encryptIO cryptKey =<< encode `fmap` readIORef ref)
