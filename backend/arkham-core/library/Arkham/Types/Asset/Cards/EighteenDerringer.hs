module Arkham.Types.Asset.Cards.EighteenDerringer
  ( eighteenDerringer
  , EighteenDerringer(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import qualified Arkham.Types.Action as Action
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Asset.Uses
import Arkham.Types.Card.CardCode
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype EighteenDerringer = EighteenDerringer AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

eighteenDerringer :: AssetCard EighteenDerringer
eighteenDerringer = hand EighteenDerringer Cards.eighteenDerringer

instance HasAbilities EighteenDerringer where
  getAbilities (EighteenDerringer attrs) =
    [ restrictedAbility attrs 1 OwnsThis
        $ ActionAbility (Just Action.Fight)
        $ Costs [ActionCost 1, UseCost (toId attrs) Ammo 1]
    ]

instance AssetRunner env => RunMessage env EighteenDerringer where
  runMessage msg a@(EighteenDerringer attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ pushAll
      [ skillTestModifiers
        attrs
        (InvestigatorTarget iid)
        [DamageDealt 1, SkillModifier SkillCombat 2]
      , CreateEffect (toCardCode attrs) Nothing source (toTarget attrs)
      , ChooseFightEnemy iid source SkillCombat mempty False
      ]
    _ -> EighteenDerringer <$> runMessage msg attrs