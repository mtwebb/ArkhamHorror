module Arkham.Agenda.Cards.MadnessDrowns
  ( MadnessDrowns
  , madnessDrowns
  ) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.Criteria
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.GameValue
import Arkham.Helpers.Modifiers
import Arkham.Helpers.Query
import Arkham.Matcher
import Arkham.Message
import Arkham.Target

newtype MadnessDrowns = MadnessDrowns AgendaAttrs
  deriving anyclass IsAgenda
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

madnessDrowns :: AgendaCard MadnessDrowns
madnessDrowns = agenda (2, A) MadnessDrowns Cards.madnessDrowns (Static 7)

instance HasModifiersFor MadnessDrowns where
  getModifiersFor _ (EnemyTarget eid) (MadnessDrowns a) = do
    isHastur <- eid `isMatch` EnemyWithTitle "Hastur"
    pure $ toModifiers a [ EnemyFight 1 | isHastur ]
  getModifiersFor _ _ _ = pure []

instance HasAbilities MadnessDrowns where
  getAbilities (MadnessDrowns a) =
    [ restrictedAbility
          a
          1
          (EnemyCriteria
          $ EnemyExists
              (EnemyWithTitle "Hastur"
              <> EnemyWithDamage (AtLeast $ PerPlayer 5)
              )
          )
        $ Objective
        $ ForcedAbility AnyWindow
    ]

instance RunMessage MadnessDrowns where
  runMessage msg a@(MadnessDrowns attrs) = case msg of
    AdvanceAgenda aid | aid == toId attrs && onSide B attrs -> do
      palaceOfTheKing <- getJustLocationIdByName "Palace of the King"
      beastOfAldebaran <- getSetAsideCard Enemies.beastOfAldebaran
      pushAll
        [ CreateEnemyAt beastOfAldebaran palaceOfTheKing Nothing
        , ShuffleEncounterDiscardBackIn
        , AdvanceAgendaDeck (agendaDeckId attrs) (toSource attrs)
        ]
      pure a
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      push $ AdvanceAgenda (toId attrs)
      pure a
    _ -> MadnessDrowns <$> runMessage msg attrs