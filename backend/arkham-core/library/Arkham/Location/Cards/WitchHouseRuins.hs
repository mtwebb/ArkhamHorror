module Arkham.Location.Cards.WitchHouseRuins (
  witchHouseRuins,
  WitchHouseRuins (..),
) where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Runner
import Arkham.Message qualified as Msg
import Arkham.SkillType

newtype WitchHouseRuins = WitchHouseRuins LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

witchHouseRuins :: LocationCard WitchHouseRuins
witchHouseRuins = location WitchHouseRuins Cards.witchHouseRuins 2 (Static 0)

instance HasAbilities WitchHouseRuins where
  getAbilities (WitchHouseRuins a) =
    withRevealedAbilities
      a
      [ limitedAbility (PlayerLimit PerGame 1) $
          restrictedAbility a 1 Here $
            ActionAbility (Just Action.Investigate) $
              ActionCost 1
      , haunted "Lose 1 action." a 2
      ]

instance RunMessage WitchHouseRuins where
  runMessage msg l@(WitchHouseRuins attrs) = case msg of
    Msg.RevealLocation _ lid | lid == toId attrs -> do
      WitchHouseRuins <$> runMessage msg (attrs & labelL .~ "witchHouseRuins")
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      push $
        Investigate
          iid
          (toId attrs)
          (toAbilitySource attrs 1)
          Nothing
          SkillIntellect
          False
      pure l
    UseCardAbility iid (isSource attrs -> True) 2 _ _ -> do
      push $ LoseActions iid (toSource attrs) 1
      pure l
    Successful (Action.Investigate, _) iid ab _ _
      | isAbilitySource attrs 1 ab -> do
          push $ HealHorror (toTarget iid) ab 2
          pure l
    _ -> WitchHouseRuins <$> runMessage msg attrs
