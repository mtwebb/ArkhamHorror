{-# LANGUAGE TemplateHaskell #-}

module Arkham.Asset.Types where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards
import Arkham.Asset.Uses
import Arkham.Card
import Arkham.ChaosToken (ChaosToken)
import Arkham.ClassSymbol
import Arkham.Classes.Entity
import Arkham.Classes.HasAbilities
import Arkham.Classes.HasModifiersFor
import Arkham.Classes.RunMessage.Internal
import Arkham.GameValue
import Arkham.Id
import Arkham.Json
import Arkham.Key
import Arkham.Name
import Arkham.Placement
import Arkham.Projection
import Arkham.Slot
import Arkham.Source
import Arkham.Target
import Arkham.Token
import Arkham.Token qualified as Token
import Arkham.Trait (Trait)
import Data.Typeable

data Asset = forall a. IsAsset a => Asset a

instance AsId Asset where
  type IdOf Asset = AssetId
  asId = toId

instance AsId AssetAttrs where
  type IdOf AssetAttrs = AssetId
  asId = toId

instance Eq Asset where
  Asset (a :: a) == Asset (b :: b) = case eqT @a @b of
    Just Refl -> a == b
    Nothing -> False

instance Show Asset where
  show (Asset a) = show a

instance ToJSON Asset where
  toJSON (Asset a) = toJSON a

instance HasAbilities Asset where
  getAbilities (Asset a) = getAbilities a

instance HasModifiersFor Asset where
  getModifiersFor target (Asset a) = getModifiersFor target a

instance Entity Asset where
  type EntityId Asset = AssetId
  type EntityAttrs Asset = AssetAttrs
  toId = toId . toAttrs
  toAttrs (Asset a) = toAttrs a
  overAttrs f (Asset a) = Asset $ overAttrs f a

data SomeAssetCard = forall a. IsAsset a => SomeAssetCard (AssetCard a)

liftAssetCard :: (forall a. AssetCard a -> b) -> SomeAssetCard -> b
liftAssetCard f (SomeAssetCard a) = f a

someAssetCardCode :: SomeAssetCard -> CardCode
someAssetCardCode = liftAssetCard cbCardCode

instance Targetable Asset where
  toTarget = toTarget . toAttrs
  isTarget = isTarget . toAttrs

instance Sourceable Asset where
  toSource = toSource . toAttrs
  isSource = isSource . toAttrs

class
  ( Typeable a
  , ToJSON a
  , FromJSON a
  , Eq a
  , Show a
  , HasAbilities a
  , HasModifiersFor a
  , RunMessage a
  , Entity a
  , EntityId a ~ AssetId
  , EntityAttrs a ~ AssetAttrs
  ) =>
  IsAsset a

type AssetCard a = CardBuilder (AssetId, Maybe InvestigatorId) a

data instance Field (DiscardedEntity Asset) :: Type -> Type where
  DiscardedAssetTraits :: Field (DiscardedEntity Asset) (Set Trait)

data instance Field (InHandEntity Asset) :: Type -> Type where
  InHandAssetCardId :: Field (InHandEntity Asset) CardId

data instance Field Asset :: Type -> Type where
  AssetTokens :: Field Asset Tokens
  AssetName :: Field Asset Name
  AssetCost :: Field Asset Int
  AssetClues :: Field Asset Int
  AssetResources :: Field Asset Int
  AssetHorror :: Field Asset Int
  AssetDamage :: Field Asset Int
  AssetRemainingHealth :: Field Asset (Maybe Int)
  AssetRemainingSanity :: Field Asset (Maybe Int)
  AssetDoom :: Field Asset Int
  AssetExhausted :: Field Asset Bool
  AssetUses :: Field Asset (Uses Int)
  AssetStartingUses :: Field Asset (Uses GameValue)
  AssetController :: Field Asset (Maybe InvestigatorId)
  AssetOwner :: Field Asset (Maybe InvestigatorId)
  AssetLocation :: Field Asset (Maybe LocationId)
  AssetCardCode :: Field Asset CardCode
  AssetCardId :: Field Asset CardId
  AssetSlots :: Field Asset [SlotType]
  AssetSealedChaosTokens :: Field Asset [ChaosToken]
  AssetPlacement :: Field Asset Placement
  AssetCardsUnderneath :: Field Asset [Card]
  -- virtual
  AssetClasses :: Field Asset (Set ClassSymbol)
  AssetTraits :: Field Asset (Set Trait)
  AssetCardDef :: Field Asset CardDef
  AssetCard :: Field Asset Card
  AssetAbilities :: Field Asset [Ability]

deriving stock instance Show (Field Asset typ)

instance ToJSON (Field Asset typ) where
  toJSON = toJSON . show

instance FromJSON (SomeField Asset) where
  parseJSON = withText "Field Asset" $ \case
    "AssetName" -> pure $ SomeField AssetName
    "AssetCost" -> pure $ SomeField AssetCost
    "AssetClues" -> pure $ SomeField AssetClues
    "AssetResources" -> pure $ SomeField AssetResources
    "AssetHorror" -> pure $ SomeField AssetHorror
    "AssetDamage" -> pure $ SomeField AssetDamage
    "AssetRemainingHealth" -> pure $ SomeField AssetRemainingHealth
    "AssetRemainingSanity" -> pure $ SomeField AssetRemainingSanity
    "AssetDoom" -> pure $ SomeField AssetDoom
    "AssetExhausted" -> pure $ SomeField AssetExhausted
    "AssetUses" -> pure $ SomeField AssetUses
    "AssetStartingUses" -> pure $ SomeField AssetStartingUses
    "AssetController" -> pure $ SomeField AssetController
    "AssetOwner" -> pure $ SomeField AssetOwner
    "AssetLocation" -> pure $ SomeField AssetLocation
    "AssetCardCode" -> pure $ SomeField AssetCardCode
    "AssetCardId" -> pure $ SomeField AssetCardId
    "AssetSlots" -> pure $ SomeField AssetSlots
    "AssetSealedChaosTokens" -> pure $ SomeField AssetSealedChaosTokens
    "AssetPlacement" -> pure $ SomeField AssetPlacement
    "AssetClasses" -> pure $ SomeField AssetClasses
    "AssetTraits" -> pure $ SomeField AssetTraits
    "AssetCardDef" -> pure $ SomeField AssetCardDef
    "AssetCard" -> pure $ SomeField AssetCard
    "AssetAbilities" -> pure $ SomeField AssetAbilities
    "AssetCardsUnderneath" -> pure $ SomeField AssetCardsUnderneath
    _ -> error "no such field"

data AssetAttrs = AssetAttrs
  { assetId :: AssetId
  , assetCardId :: CardId
  , assetCardCode :: CardCode
  , assetOriginalCardCode :: CardCode
  , assetPlacement :: Placement
  , assetOwner :: Maybe InvestigatorId
  , assetController :: Maybe InvestigatorId
  , assetSlots :: [SlotType]
  , assetHealth :: Maybe Int
  , assetSanity :: Maybe Int
  , assetUses :: Uses Int
  , assetExhausted :: Bool
  , assetTokens :: Tokens
  , assetCanLeavePlayByNormalMeans :: Bool
  , assetDiscardWhenNoUses :: Bool
  , assetIsStory :: Bool
  , assetCardsUnderneath :: [Card]
  , assetSealedChaosTokens :: [ChaosToken]
  , assetKeys :: Set ArkhamKey
  }
  deriving stock (Show, Eq, Generic)

assetDoom :: AssetAttrs -> Int
assetDoom = countTokens Doom . assetTokens

assetClues :: AssetAttrs -> Int
assetClues = countTokens Clue . assetTokens

assetDamage :: AssetAttrs -> Int
assetDamage = countTokens Damage . assetTokens

assetHorror :: AssetAttrs -> Int
assetHorror = countTokens Horror . assetTokens

assetResources :: AssetAttrs -> Int
assetResources = countTokens Token.Resource . assetTokens

allAssetCards :: Map CardCode CardDef
allAssetCards =
  allPlayerAssetCards <> allEncounterAssetCards <> allSpecialPlayerAssetCards

instance HasCardCode AssetAttrs where
  toCardCode = assetCardCode

instance HasCardDef AssetAttrs where
  toCardDef a = case lookup (assetCardCode a) allAssetCards of
    Just def -> def
    Nothing -> error $ "missing card def for asset " <> show (assetCardCode a)

instance ToJSON AssetAttrs where
  toJSON = genericToJSON $ aesonOptions $ Just "asset"

instance FromJSON AssetAttrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "asset"

instance IsCard AssetAttrs where
  toCardId = assetCardId
  toCard a = case lookupCard (assetOriginalCardCode a) (toCardId a) of
    PlayerCard pc -> PlayerCard $ pc {pcOwner = assetOwner a}
    ec -> ec
  toCardOwner = assetOwner

asset
  :: (AssetAttrs -> a)
  -> CardDef
  -> CardBuilder (AssetId, Maybe InvestigatorId) a
asset f cardDef = assetWith f cardDef id

assetWith
  :: (AssetAttrs -> a)
  -> CardDef
  -> (AssetAttrs -> AssetAttrs)
  -> CardBuilder (AssetId, Maybe InvestigatorId) a
assetWith f cardDef g =
  CardBuilder
    { cbCardCode = cdCardCode cardDef
    , cbCardBuilder = \cardId (aid, mOwner) ->
        f . g $
          AssetAttrs
            { assetId = aid
            , assetCardId = cardId
            , assetCardCode = toCardCode cardDef
            , assetOriginalCardCode = toCardCode cardDef
            , assetOwner = mOwner
            , assetController = mOwner
            , assetPlacement = Unplaced
            , assetSlots = cdSlots cardDef
            , assetHealth = Nothing
            , assetSanity = Nothing
            , assetUses = NoUses
            , assetExhausted = False
            , assetTokens = mempty
            , assetCanLeavePlayByNormalMeans = True
            , assetDiscardWhenNoUses = False
            , assetIsStory = False
            , assetCardsUnderneath = []
            , assetSealedChaosTokens = []
            , assetKeys = mempty
            }
    }

instance Entity AssetAttrs where
  type EntityId AssetAttrs = AssetId
  type EntityAttrs AssetAttrs = AssetAttrs
  toId = assetId
  toAttrs = id
  overAttrs f = f

instance Named AssetAttrs where
  toName = toName . toCardDef

instance Targetable AssetAttrs where
  toTarget = AssetTarget . toId
  isTarget attrs@AssetAttrs {..} = \case
    AssetTarget aid -> aid == assetId
    CardCodeTarget cardCode -> cdCardCode (toCardDef attrs) == cardCode
    CardIdTarget cardId -> cardId == assetCardId
    SkillTestInitiatorTarget target -> isTarget attrs target
    _ -> False

instance Sourceable AssetAttrs where
  toSource = AssetSource . toId
  isSource AssetAttrs {assetId} (AssetSource aid) = assetId == aid
  isSource _ _ = False

controlledBy :: AssetAttrs -> InvestigatorId -> Bool
controlledBy AssetAttrs {..} iid = case assetPlacement of
  InPlayArea iid' -> iid == iid'
  AttachedToAsset _ (Just (InPlayArea iid')) -> iid == iid'
  _ -> False

attachedToEnemy :: AssetAttrs -> EnemyId -> Bool
attachedToEnemy AssetAttrs {..} eid = case assetPlacement of
  AttachedToEnemy eid' -> eid == eid'
  _ -> False

whenControlledBy
  :: Applicative m => AssetAttrs -> InvestigatorId -> m [Ability] -> m [Ability]
whenControlledBy a iid f = if controlledBy a iid then f else pure []

makeLensesWith suffixedFields ''AssetAttrs

getOwner :: HasCallStack => AssetAttrs -> InvestigatorId
getOwner = fromJustNote "asset must be owned" . view ownerL

getController :: HasCallStack => AssetAttrs -> InvestigatorId
getController = fromJustNote "asset must be controlled" . view controllerL

ally
  :: (AssetAttrs -> a)
  -> CardDef
  -> (Int, Int)
  -> CardBuilder (AssetId, Maybe InvestigatorId) a
ally f cardDef stats = allyWith f cardDef stats id

allyWith
  :: (AssetAttrs -> a)
  -> CardDef
  -> (Int, Int)
  -> (AssetAttrs -> AssetAttrs)
  -> CardBuilder (AssetId, Maybe InvestigatorId) a
allyWith f cardDef (health, sanity) g =
  assetWith
    f
    cardDef
    (g . setSanity . setHealth)
 where
  setHealth = healthL .~ (health <$ guard (health > 0))
  setSanity = sanityL .~ (sanity <$ guard (sanity > 0))
