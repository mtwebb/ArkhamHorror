module Arkham.Location.Cards.OvergrownCairns (
  OvergrownCairns (..),
  overgrownCairns,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.Damage
import Arkham.GameValue
import Arkham.Helpers.Investigator
import Arkham.Location.Cards qualified as Cards (overgrownCairns)
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher

newtype OvergrownCairns = OvergrownCairns LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

overgrownCairns :: LocationCard OvergrownCairns
overgrownCairns = location OvergrownCairns Cards.overgrownCairns 4 (Static 0)

instance HasAbilities OvergrownCairns where
  getAbilities (OvergrownCairns attrs) =
    withBaseAbilities
      attrs
      [ limitedAbility (PlayerLimit PerGame 1)
        $ restrictedAbility
          attrs
          1
          ( Here
              <> InvestigatorExists
                (HealableInvestigator (toSource attrs) HorrorType You)
          )
        $ ActionAbility Nothing
        $ Costs [ActionCost 1, ResourceCost 2]
      | locationRevealed attrs
      ]

instance RunMessage OvergrownCairns where
  runMessage msg l@(OvergrownCairns attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source -> do
      mHealHorror <- getHealHorrorMessage attrs 2 iid
      for_ mHealHorror push
      pure l
    _ -> OvergrownCairns <$> runMessage msg attrs
