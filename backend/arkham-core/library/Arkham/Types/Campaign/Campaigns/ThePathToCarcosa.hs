module Arkham.Types.Campaign.Campaigns.ThePathToCarcosa
  ( ThePathToCarcosa(..)
  , thePathToCarcosa
  ) where

import Arkham.Prelude

import Arkham.Campaigns.ThePathToCarcosa.Import
import Arkham.Types.Campaign.Attrs
import Arkham.Types.Campaign.Runner
import Arkham.Types.CampaignId
import Arkham.Types.CampaignStep
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import Arkham.Types.Game.Helpers
import Arkham.Types.Matcher
import Arkham.Types.Message

newtype ThePathToCarcosa = ThePathToCarcosa CampaignAttrs
  deriving anyclass IsCampaign
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq)

thePathToCarcosa :: Difficulty -> ThePathToCarcosa
thePathToCarcosa difficulty = ThePathToCarcosa $ baseAttrs
  (CampaignId "03")
  "The Path to Carcosa"
  difficulty
  (chaosBagContents difficulty)

instance CampaignRunner env => RunMessage env ThePathToCarcosa where
  runMessage msg c@(ThePathToCarcosa a) = case msg of
    CampaignStep (Just PrologueStep) -> do
      investigatorIds <- getInvestigatorIds
      lolaHayesChosen <- isJust
        <$> selectOne (InvestigatorWithTitle "Lola Hayes")
      c <$ pushAll
        ([story investigatorIds prologue]
        <> [ story investigatorIds lolaPrologue | lolaHayesChosen ]
        <> [NextCampaignStep Nothing]
        )
    NextCampaignStep _ -> do
      let step = nextStep a
      push (CampaignStep step)
      pure
        . ThePathToCarcosa
        $ a
        & (stepL .~ step)
        & (completedStepsL %~ completeStep (campaignStep a))
    _ -> ThePathToCarcosa <$> runMessage msg a