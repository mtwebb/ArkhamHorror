module Arkham.Cost.FieldCost where

-- This module is a hot mess because we need to bring A LOT into scope in order
-- for this to be valid. Additionally we can't avoid the entity types being in
-- scope because hs-boot files can not have associated type families. In order
-- to circumvent this we have to have the Cost in an hs-boot file, but
-- unfortunately this causes a recompilation of Message, when it uses
-- TemplateHaskell, which has the worse compilation performance so Message
-- needed to be changed to Generic, which has exponential memory usage

import Arkham.Prelude

import Arkham.Classes.Entity
import Arkham.Classes.Query
import Arkham.Field
import {-# SOURCE #-} Arkham.Game ()
import Arkham.Location.Types
import Arkham.Matcher
import Arkham.Projection
import Arkham.Query
import Data.Typeable

data FieldCost where
  FieldCost
    :: forall matcher rec fld
     . ( fld ~ Field rec Int
       , QueryElement matcher ~ EntityId rec
       , Typeable matcher
       , Typeable rec
       , Typeable fld
       , Show matcher
       , Show fld
       , ToJSON matcher
       , ToJSON fld
       , Ord fld
       , Ord matcher
       , FromJSON (SomeField rec)
       , Projection rec
       , Query matcher
       )
    => matcher
    -> fld
    -> FieldCost

deriving stock instance Show FieldCost

instance Eq FieldCost where
  FieldCost (m1 :: m1) (f1 :: f1) == FieldCost (m2 :: m2) (f2 :: f2) = case eqT @m1 @m2 of
    Just Refl -> case eqT @f1 @f2 of
      Just Refl -> m1 == m2 && f1 == f2
      Nothing -> False
    Nothing -> False

instance ToJSON FieldCost where
  toJSON (FieldCost matcher (fld :: Field rec typ)) =
    object
      [ "matcher" .= matcher
      , "field" .= fld
      , "entity" .= show (typeRep $ Proxy @rec)
      ]

instance FromJSON FieldCost where
  parseJSON = withObject "FieldCost" $ \v -> do
    entityType :: Text <- v .: "entity"
    case entityType of
      "Location" -> do
        sfld :: SomeField Location <- v .: "field"
        case sfld of
          SomeField (fld :: Field Location typ) ->
            case eqT @typ @Int of
              Just Refl -> do
                mtchr :: LocationMatcher <- v .: "matcher"
                pure $ FieldCost mtchr fld
              _ -> error "Must be an int"
      _ -> error "Unhandled"

-- we do not care about this instance really
instance Ord FieldCost where
  compare f1 f2 = compare (show f1) (show f2)
