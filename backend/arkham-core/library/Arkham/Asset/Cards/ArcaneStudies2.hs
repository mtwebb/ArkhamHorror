module Arkham.Asset.Cards.ArcaneStudies2 (
  ArcaneStudies2 (..),
  arcaneStudies2,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Matcher
import Arkham.SkillType

newtype ArcaneStudies2 = ArcaneStudies2 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arcaneStudies2 :: AssetCard ArcaneStudies2
arcaneStudies2 = asset ArcaneStudies2 Cards.arcaneStudies2

instance HasAbilities ArcaneStudies2 where
  getAbilities (ArcaneStudies2 a) =
    [ withTooltip
        "{fast} Spend 1 resource: You get +1 {willpower} for this skill test."
        $ restrictedAbility a 1 (ControlsThis <> DuringSkillTest AnySkillTest)
        $ FastAbility
        $ ResourceCost 1
    , withTooltip
        "{fast} Spend 1 resource: You get +1 {intellect} for this skill test."
        $ restrictedAbility a 2 (ControlsThis <> DuringSkillTest AnySkillTest)
        $ FastAbility
        $ ResourceCost 1
    ]

instance RunMessage ArcaneStudies2 where
  runMessage msg a@(ArcaneStudies2 attrs) = case msg of
    UseCardAbility iid source 1 _ _
      | isSource attrs source ->
          a
            <$ push
              ( skillTestModifier
                  attrs
                  (InvestigatorTarget iid)
                  (SkillModifier SkillWillpower 1)
              )
    UseCardAbility iid source 2 _ _
      | isSource attrs source ->
          a
            <$ push
              ( skillTestModifier
                  attrs
                  (InvestigatorTarget iid)
                  (SkillModifier SkillIntellect 1)
              )
    _ -> ArcaneStudies2 <$> runMessage msg attrs
