module Arkham.Investigator.Cards.FinnEdwards (
  finnEdwards,
  FinnEdwards (..),
) where

import Arkham.Prelude

import Arkham.Action qualified as Action
import Arkham.Action.Additional
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Location.Types (Field (..))
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection

newtype FinnEdwards = FinnEdwards InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

finnEdwards :: InvestigatorCard FinnEdwards
finnEdwards =
  investigator
    FinnEdwards
    Cards.finnEdwards
    Stats
      { health = 7
      , sanity = 7
      , willpower = 1
      , intellect = 4
      , combat = 3
      , agility = 4
      }

instance HasAbilities FinnEdwards where
  getAbilities (FinnEdwards _) = []

instance HasChaosTokenValue FinnEdwards where
  getChaosTokenValue iid ElderSign (FinnEdwards attrs) | iid == toId attrs = do
    n <- selectCount ExhaustedEnemy
    pure $ ChaosTokenValue ElderSign (PositiveModifier n)
  getChaosTokenValue _ token _ = pure $ ChaosTokenValue token mempty

instance RunMessage FinnEdwards where
  runMessage msg i@(FinnEdwards attrs) = case msg of
    PassedSkillTest iid _ _ (ChaosTokenTarget token) _ n
      | iid == toId attrs && n >= 2 -> do
          when (chaosTokenFace token == ElderSign) $ do
            mlid <- selectOne $ locationWithInvestigator iid
            for_ mlid $ \lid -> do
              canDiscover <- getCanDiscoverClues attrs lid
              hasClues <- fieldP LocationClues (> 0) lid
              when (hasClues && canDiscover) $
                push $
                  chooseOne
                    iid
                    [ Label
                        "Discover 1 clue at your location"
                        [InvestigatorDiscoverCluesAtTheirLocation iid (toSource attrs) 1 Nothing]
                    , Label "Do not discover a clue" []
                    ]
          pure i
    Setup ->
      FinnEdwards
        <$> runMessage
          msg
          ( attrs
              & additionalActionsL
              %~ (ActionRestrictedAdditionalAction Action.Evade :)
          )
    BeginRound ->
      FinnEdwards
        <$> runMessage
          msg
          ( attrs
              & additionalActionsL
              %~ (ActionRestrictedAdditionalAction Action.Evade :)
          )
    _ -> FinnEdwards <$> runMessage msg attrs
