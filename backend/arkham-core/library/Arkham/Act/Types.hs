module Arkham.Act.Types where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Act.Cards
import Arkham.Act.Sequence qualified as AS
import Arkham.Card
import Arkham.Classes.Entity
import Arkham.Classes.HasAbilities
import Arkham.Classes.HasModifiersFor
import Arkham.Classes.RunMessage.Internal
import Arkham.Cost
import Arkham.Id
import Arkham.Json
import Arkham.Name
import Arkham.Projection
import Arkham.Source
import Arkham.Target
import Data.Typeable

class (Typeable a, ToJSON a, FromJSON a, Eq a, Show a, HasAbilities a, HasModifiersFor a, RunMessage a, Entity a, EntityId a ~ ActId, EntityAttrs a ~ ActAttrs) => IsAct a

type ActCard a = CardBuilder (Int, ActId) a

data instance Field Act :: Type -> Type where
  ActSequence :: Field Act AS.ActSequence
  ActClues :: Field Act Int
  ActAbilities :: Field Act [Ability]

data ActAttrs = ActAttrs
  { actId :: ActId
  , actSequence :: AS.ActSequence
  , actAdvanceCost :: Maybe Cost
  , actClues :: Int
  , actTreacheries :: HashSet TreacheryId
  , actDeckId :: Int
  }
  deriving stock (Show, Eq, Generic)

sequenceL :: Lens' ActAttrs AS.ActSequence
sequenceL = lens actSequence $ \m x -> m { actSequence = x }

cluesL :: Lens' ActAttrs Int
cluesL = lens actClues $ \m x -> m { actClues = x }

treacheriesL :: Lens' ActAttrs (HashSet TreacheryId)
treacheriesL = lens actTreacheries $ \m x -> m { actTreacheries = x }

actWith
  :: (Int, AS.ActSide)
  -> (ActAttrs -> a)
  -> CardDef
  -> Maybe Cost
  -> (ActAttrs -> ActAttrs)
  -> CardBuilder (Int, ActId) a
actWith (n, side) f cardDef mCost g = CardBuilder
  { cbCardCode = cdCardCode cardDef
  , cbCardBuilder = \(deckId, aid) -> f . g $ ActAttrs
    { actId = aid
    , actSequence = AS.Sequence n side
    , actClues = 0
    , actAdvanceCost = mCost
    , actTreacheries = mempty
    , actDeckId = deckId
    }
  }

act
  :: (Int, AS.ActSide)
  -> (ActAttrs -> a)
  -> CardDef
  -> Maybe Cost
  -> CardBuilder (Int, ActId) a
act actSeq f cardDef mCost = actWith actSeq f cardDef mCost id

instance HasCardDef ActAttrs where
  toCardDef e = case lookup (unActId $ actId e) allActCards of
    Just def -> def
    Nothing -> error $ "missing card def for act " <> show (unActId $ actId e)

instance ToJSON ActAttrs where
  toJSON = genericToJSON $ aesonOptions $ Just "act"
  toEncoding = genericToEncoding $ aesonOptions $ Just "act"

instance FromJSON ActAttrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "act"

instance Entity ActAttrs where
  type EntityId ActAttrs = ActId
  type EntityAttrs ActAttrs = ActAttrs
  toId = actId
  toAttrs = id
  overAttrs f = f

instance Named ActAttrs where
  toName = toName . toCardDef

instance TargetEntity ActAttrs where
  toTarget = ActTarget . toId
  isTarget ActAttrs { actId } (ActTarget aid) = actId == aid
  isTarget _ _ = False

instance SourceEntity ActAttrs where
  toSource = ActSource . toId
  isSource ActAttrs { actId } (ActSource aid) = actId == aid
  isSource _ _ = False

onSide :: AS.ActSide -> ActAttrs -> Bool
onSide side ActAttrs {..} = AS.actSide actSequence == side

instance HasAbilities ActAttrs where
  getAbilities attrs@ActAttrs {..} = case actAdvanceCost of
    Just cost -> [mkAbility attrs 999 (Objective $ FastAbility cost)]
    Nothing -> []

data Act = forall a. IsAct a => Act a

instance Eq Act where
  (Act (a :: a)) == (Act (b :: b)) = case eqT @a @b of
    Just Refl -> a == b
    Nothing -> False

instance Show Act where
  show (Act a) = show a

instance ToJSON Act where
  toJSON (Act a) = toJSON a

instance HasAbilities Act where
  getAbilities (Act a) = getAbilities a

instance HasModifiersFor Act where
  getModifiersFor source target (Act a) = getModifiersFor source target a

instance Entity Act where
  type EntityId Act = ActId
  type EntityAttrs Act = ActAttrs
  toId = toId . toAttrs
  toAttrs (Act a) = toAttrs a
  overAttrs f (Act a) = Act $ overAttrs f a

instance TargetEntity Act where
  toTarget = toTarget . toAttrs
  isTarget = isTarget . toAttrs

instance SourceEntity Act where
  toSource = toSource . toAttrs
  isSource = isSource . toAttrs

data SomeActCard = forall a. IsAct a => SomeActCard (ActCard a)

liftSomeActCard :: (forall a. ActCard a -> b) -> SomeActCard -> b
liftSomeActCard f (SomeActCard a) = f a

someActCardCode :: SomeActCard -> CardCode
someActCardCode = liftSomeActCard cbCardCode