module Arkham.Asset.Cards.AceOfSwords1 (
  aceOfSwords1,
  AceOfSwords1 (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Timing qualified as Timing

newtype AceOfSwords1 = AceOfSwords1 AssetAttrs
  deriving anyclass (IsAsset)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aceOfSwords1 :: AssetCard AceOfSwords1
aceOfSwords1 =
  asset AceOfSwords1 Cards.aceOfSwords1

instance HasModifiersFor AceOfSwords1 where
  getModifiersFor (InvestigatorTarget iid) (AceOfSwords1 a) =
    pure $
      toModifiers a [SkillModifier SkillCombat 1 | controlledBy a iid]
  getModifiersFor _ _ = pure []

instance HasAbilities AceOfSwords1 where
  getAbilities (AceOfSwords1 a) =
    [reactionAbility a 1 Free (GameBegins Timing.When) InYourHand]

instance RunMessage AceOfSwords1 where
  runMessage msg a@(AceOfSwords1 attrs) = case msg of
    InHand _ (UseCardAbility iid (isSource attrs -> True) 1 _ _) -> do
      push $ putCardIntoPlay iid attrs
      pure a
    _ -> AceOfSwords1 <$> runMessage msg attrs
