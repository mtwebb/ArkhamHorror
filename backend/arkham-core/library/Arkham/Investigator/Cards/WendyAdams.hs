module Arkham.Investigator.Cards.WendyAdams (
  WendyAdams (..),
  wendyAdams,
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Assets
import Arkham.Game.Helpers
import Arkham.Investigator.Cards qualified as Cards
import Arkham.Investigator.Runner
import Arkham.Matcher
import Arkham.Message hiding (RevealChaosToken)
import Arkham.Timing qualified as Timing
import Arkham.Window qualified as Window

newtype WendyAdams = WendyAdams InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wendyAdams :: InvestigatorCard WendyAdams
wendyAdams =
  investigator
    WendyAdams
    Cards.wendyAdams
    Stats
      { health = 7
      , sanity = 7
      , willpower = 4
      , intellect = 3
      , combat = 1
      , agility = 4
      }

instance HasChaosTokenValue WendyAdams where
  getChaosTokenValue iid ElderSign (WendyAdams attrs) | iid == toId attrs = do
    pure $ ChaosTokenValue ElderSign $ PositiveModifier 0
  getChaosTokenValue _ token _ = pure $ ChaosTokenValue token mempty

instance HasAbilities WendyAdams where
  getAbilities (WendyAdams attrs) =
    [ limitedAbility (PlayerLimit PerTestOrAbility 1) $
        restrictedAbility attrs 1 Self $
          ReactionAbility (RevealChaosToken Timing.When You AnyChaosToken) $
            HandDiscardCost 1 AnyCard
    ]

instance RunMessage WendyAdams where
  runMessage msg i@(WendyAdams attrs@InvestigatorAttrs {..}) = case msg of
    UseCardAbility _ (isSource attrs -> True) 1 (Window.revealedChaosTokens -> [token]) _ -> do
      cancelChaosToken token
      pushAll
        [ CancelEachNext
            (toSource attrs)
            [RunWindowMessage, DrawChaosTokenMessage, RevealChaosTokenMessage]
        , ReturnChaosTokens [token]
        , UnfocusChaosTokens
        , DrawAnotherChaosToken (toId attrs)
        ]
      pure i
    ResolveChaosToken _ ElderSign iid | iid == investigatorId -> do
      maid <- selectOne $ assetIs Assets.wendysAmulet
      when (isJust maid) (push PassSkillTest)
      pure i
    _ -> WendyAdams <$> runMessage msg attrs
