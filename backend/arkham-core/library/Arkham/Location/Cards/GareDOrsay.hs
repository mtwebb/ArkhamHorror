module Arkham.Location.Cards.GareDOrsay (
  gareDOrsay,
  GareDOrsay (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher hiding (MoveAction)
import Arkham.Message qualified as Msg
import Arkham.Trait

newtype GareDOrsay = GareDOrsay LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

gareDOrsay :: LocationCard GareDOrsay
gareDOrsay = location GareDOrsay Cards.gareDOrsay 4 (PerPlayer 1)

instance HasAbilities GareDOrsay where
  getAbilities (GareDOrsay attrs) =
    withBaseAbilities
      attrs
      [restrictedAbility attrs 1 Here $ ActionAbility Nothing $ ActionCost 1]

instance RunMessage GareDOrsay where
  runMessage msg l@(GareDOrsay attrs) = case msg of
    UseCardAbility iid (isSource attrs -> True) 1 _ _ -> do
      rails <- filter (/= toId attrs) <$> selectList (LocationWithTrait Rail)
      push $
        chooseOne
          iid
          [ targetLabel lid [Msg.MoveAction iid lid Free False]
          | lid <- rails
          ]
      pure l
    _ -> GareDOrsay <$> runMessage msg attrs
