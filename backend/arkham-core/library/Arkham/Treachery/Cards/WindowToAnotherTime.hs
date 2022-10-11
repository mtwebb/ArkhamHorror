module Arkham.Treachery.Cards.WindowToAnotherTime
  ( windowToAnotherTime
  , WindowToAnotherTime(..)
  ) where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Deck
import Arkham.Location.Types ( Field (..) )
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Scenario.Deck
import Arkham.Trait ( Trait (Ancient) )
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Runner

newtype WindowToAnotherTime = WindowToAnotherTime TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

windowToAnotherTime :: TreacheryCard WindowToAnotherTime
windowToAnotherTime = treachery WindowToAnotherTime Cards.windowToAnotherTime

instance RunMessage WindowToAnotherTime where
  runMessage msg t@(WindowToAnotherTime attrs) = case msg of
    Revelation iid source | isSource attrs source -> do
      ancientLocations <- selectList $ LocationWithTrait Ancient
      ancientLocationsWithCards <- traverse
        (traverseToSnd (field LocationCard))
        ancientLocations
      push
        $ chooseOrRunOne iid
        $ Label
            "Place Doom on the Current Agenda"
            [PlaceDoomOnAgenda, AdvanceAgendaIfThresholdSatisfied]
        : [ targetLabel
              lid
              [ RemoveLocation lid
              , ShuffleCardsIntoDeck (ScenarioDeckByKey ExplorationDeck) [card]
              ]
          | (lid, card) <- ancientLocationsWithCards
          ]
      pure t
    _ -> WindowToAnotherTime <$> runMessage msg attrs