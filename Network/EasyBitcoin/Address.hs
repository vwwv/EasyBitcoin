{-# LANGUAGE ScopedTypeVariables #-}
module Network.EasyBitcoin.Address 
  where


import Network.EasyBitcoin.Internal.Words
import Network.EasyBitcoin.Internal.Serialization.Base58 ( encodeBase58
                                                         , decodeBase58
                                                         , addRedundancy
                                                         , liftRedundacy
                                                         )

import Network.EasyBitcoin.Internal.Serialization.ByteString
import Network.EasyBitcoin.Internal.InstanciationHelpers
import Network.EasyBitcoin.Internal.HashFunctions
import Network.EasyBitcoin.Internal.Keys (PrvKey(), PubKey(),Compressed(..))
import Network.EasyBitcoin.Keys
import Network.EasyBitcoin.NetworkParams
import qualified Data.ByteString as BS
import Data.Char(isSpace)
import Data.Word

-- | Bitcoin address, either Pay2PKH or Pay2SH
data Address       net = PubKeyAddress { getAddrHash :: Word160 }
                       | ScriptAddress { getAddrHash :: Word160 } -- TODO, it will broke if ever receive the other kind----> refactor!!
                       deriving (Eq, Ord)



-- | Values from where an address can be derived. Keys, are interpreted as compressed by default, if need to derive an address from
--   an uncompressed key, use 'addressFromUncompressed' instead.
class Addressable add where
   address :: (BlockNetwork net) => add net -> Address net  



instance Addressable (Key v) where
    address = PubKeyAddress . hash160 . hash256BS . encode' . Compressed True. pub_key . derivePublic
 

-- | Derive an address from a key treating it as uncompressed.
addressFromUncompressed:: Key v net -> Address net
addressFromUncompressed = PubKeyAddress . hash160 . hash256BS . encode' . Compressed False . pub_key . derivePublic


instance (BlockNetwork net) => ToJSON (Address net) where
  toJSON = toJSON.show



isPay2SH  :: Address net -> Bool
isPay2SH  addr = case addr of 
                  PubKeyAddress _ -> True
                  _               -> False

isPay2PKH :: Address net -> Bool
isPay2PKH addr = case addr of 
                  ScriptAddress _ -> True
                  _               -> False

---------------------------------------------------------------------------------------------------------------------------------
instance (BlockNetwork net ) => Show (Address net) where
    show = show_aux
      where
        show_aux :: forall net . (BlockNetwork net ) =>  Address net -> String
        show_aux addr = let params = (valuesOf :: Params net)
                         in case addr of
                              PubKeyAddress payload -> show_ (addrPrefix params) payload
                              ScriptAddress payload -> show_ (scriptPrefix params) payload

 
instance (BlockNetwork net ) => Read (Address net) where
    readsPrec _ = read_aux
      where
        read_aux :: forall net . (BlockNetwork net ) =>  ReadS (Address net)
        read_aux str = let params = (valuesOf :: Params net)
                        
                        in case readsPrec_ str of

                            ( Just (prefix, payload), rest) 
                                  | addrPrefix params   == prefix   -> [(PubKeyAddress payload, rest)]
                                  | scriptPrefix params == prefix   -> [(ScriptAddress payload, rest)]

                            _                                       -> []



instance (BlockNetwork net ) => ToField (Address net) where
    toField = genericWriteField


instance (BlockNetwork net ) => FromField (Address net) where
    fromField = genericReadField
----------------------------------------------------------------------------------------------------------------------------------

{-

instance Show (Address MainNet) where
    show (PubKeyAddress payload) = show_ addrPrefixMainNet payload
    show (ScriptAddress payload) = show_ scriptPrefixMainNet payload


instance Read (Address MainNet) where
    readsPrec _ str = case readsPrec_ str of 
                        ( Just (prefix, payload), rest) 
                              | addrPrefixMainNet   == prefix   -> [(PubKeyAddress payload, rest)]
                              | scriptPrefixMainNet == prefix   -> [(ScriptAddress payload, rest)]
                        _                                       -> [] 


instance Show (Address TestNet3) where
    show (PubKeyAddress payload) = show_ addrPrefixTestNet3   payload
    show (ScriptAddress payload) = show_ scriptPrefixTestNet3 payload
           

instance Read (Address TestNet3) where
    readsPrec _ str = case readsPrec_ str of 
                        ( Just (prefix, payload), rest) 
                              | addrPrefixTestNet3   == prefix  -> [(PubKeyAddress payload, rest)]
                              | scriptPrefixTestNet3 == prefix  -> [(ScriptAddress payload, rest)]
                        _                                       -> [] 


show_ prefix payload = decodeBase58 . addRedundancy $ BS.cons prefix (encode' payload)

deriveAddressFromPub :: PubKey net -> Address net 
deriveAddressFromPub (PubKey c k) = PubKeyAddress . hash160 . hash256BS . encode' $ PWC c k  


-}












