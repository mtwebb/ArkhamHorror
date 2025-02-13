module Arkham.Investigator.Cards.WilliamYorick where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Card
import Arkham.Game.Helpers
import Arkham.Id
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Matcher
import Arkham.Message hiding (EnemyDefeated)
import Arkham.Timing qualified as Timing
import Arkham.Window (Window (..))
import Arkham.Window qualified as Window

newtype WilliamYorick = WilliamYorick InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

williamYorick :: InvestigatorCard WilliamYorick
williamYorick =
  investigator
    WilliamYorick
    Cards.williamYorick
    Stats
      { health = 8
      , sanity = 6
      , willpower = 3
      , intellect = 2
      , combat = 4
      , agility = 3
      }

instance HasChaosTokenValue WilliamYorick where
  getChaosTokenValue iid ElderSign (WilliamYorick attrs)
    | iid == investigatorId attrs =
        pure $
          ChaosTokenValue ElderSign (PositiveModifier 2)
  getChaosTokenValue _ token _ = pure $ ChaosTokenValue token mempty

instance HasAbilities WilliamYorick where
  getAbilities (WilliamYorick attrs) =
    [ limitedAbility (PlayerLimit PerRound 1) $
        reaction
          attrs
          1
          ( Self
              <> PlayableCardInDiscard (DiscardOf You) (CardWithType AssetType)
          )
          Free
          (EnemyDefeated Timing.After You ByAny AnyEnemy)
    ]

instance RunMessage WilliamYorick where
  runMessage msg i@(WilliamYorick attrs) = case msg of
    UseCardAbility iid source 1 windows' _ | isSource attrs source -> do
      let
        windows'' =
          nub $
            windows'
              <> [ Window Timing.When Window.NonFast
                 , Window Timing.When (Window.DuringTurn iid)
                 ]
        targets =
          filter ((== AssetType) . toCardType) (investigatorDiscard attrs)
        playCardMsgs c =
          [addToHand iid c]
            <> if isFastCard c
              then [InitiatePlayCard iid c Nothing windows'' False]
              else [PayCardCost iid c windows'']
      playableTargets <-
        filterM
          (getIsPlayable iid source UnpaidCost windows'' . PlayerCard)
          targets
      push $
        chooseOne iid $
          [ targetLabel
            (toCardId card)
            (playCardMsgs $ PlayerCard card)
          | card <- playableTargets
          ]
      pure i
    ResolveChaosToken _ ElderSign iid | iid == toId attrs -> do
      push $
        CreateEffect
          (unInvestigatorId $ toId attrs)
          Nothing
          (ChaosTokenEffectSource ElderSign)
          (InvestigatorTarget iid)
      pure i
    _ -> WilliamYorick <$> runMessage msg attrs
