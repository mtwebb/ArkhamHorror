module Arkham.Campaign.Campaigns.ThePathToCarcosa (
  ThePathToCarcosa (..),
  thePathToCarcosa,
) where

import Arkham.Prelude

import Arkham.Campaign.Runner
import Arkham.CampaignLogKey
import Arkham.CampaignStep
import Arkham.Campaigns.ThePathToCarcosa.Import
import Arkham.Card
import Arkham.ChaosToken
import Arkham.Classes
import Arkham.Difficulty
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Game.Helpers
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Id
import Arkham.Matcher hiding (EnemyDefeated)
import Arkham.Message

newtype ThePathToCarcosa = ThePathToCarcosa CampaignAttrs
  deriving newtype (Show, ToJSON, FromJSON, Entity, Eq, HasModifiersFor)

instance IsCampaign ThePathToCarcosa where
  nextStep a = case campaignStep (toAttrs a) of
    PrologueStep -> Just CurtainCall
    CurtainCall -> Just (UpgradeDeckStep TheLastKing)
    TheLastKing -> Just (UpgradeDeckStep EchoesOfThePast)
    InterludeStep 1 _ -> Just (UpgradeDeckStep EchoesOfThePast)
    EchoesOfThePast -> Just (UpgradeDeckStep TheUnspeakableOath)
    TheUnspeakableOath -> Just (UpgradeDeckStep APhantomOfTruth)
    InterludeStep 2 _ -> Just (UpgradeDeckStep APhantomOfTruth)
    APhantomOfTruth -> Just (UpgradeDeckStep ThePallidMask)
    ThePallidMask -> Just (UpgradeDeckStep BlackStarsRise)
    BlackStarsRise -> Just (UpgradeDeckStep DimCarcosa)
    DimCarcosa -> Just EpilogueStep
    UpgradeDeckStep nextStep' -> Just nextStep'
    _ -> Nothing

thePathToCarcosa :: Difficulty -> ThePathToCarcosa
thePathToCarcosa difficulty =
  campaign
    ThePathToCarcosa
    (CampaignId "03")
    "The Path to Carcosa"
    difficulty
    (chaosBagContents difficulty)

instance RunMessage ThePathToCarcosa where
  runMessage msg c = case msg of
    CampaignStep PrologueStep -> do
      investigatorIds <- allInvestigatorIds
      lolaHayesChosen <- selectAny (InvestigatorWithTitle "Lola Hayes")
      pushAll $
        [story investigatorIds prologue]
          <> [story investigatorIds lolaPrologue | lolaHayesChosen]
          <> [NextCampaignStep Nothing]
      pure c
    CampaignStep (InterludeStep 1 _) -> do
      leadInvestigatorId <- getLeadInvestigatorId
      investigatorIds <- allInvestigatorIds
      doubt <- getRecordCount Doubt
      conviction <- getRecordCount Conviction
      push $
        chooseOne
          leadInvestigatorId
          [ Label
              "Things seem to have calmed down. Perhaps we should go back inside and investigate further."
              [ story investigatorIds lunacysReward1
              , Record YouIntrudedOnASecretMeeting
              , RecordCount Doubt (doubt + 1)
              , RemoveAllChaosTokens Cultist
              , RemoveAllChaosTokens Tablet
              , RemoveAllChaosTokens ElderThing
              , AddChaosToken ElderThing
              , AddChaosToken ElderThing
              , NextCampaignStep Nothing
              ]
          , Label
              "I don't trust this place one bit. Letbs block the door and get the hell out of here!"
              [ story investigatorIds lunacysReward2
              , Record YouFledTheDinnerParty
              , RemoveAllChaosTokens Cultist
              , RemoveAllChaosTokens Tablet
              , RemoveAllChaosTokens ElderThing
              , AddChaosToken Tablet
              , AddChaosToken Tablet
              , NextCampaignStep Nothing
              ]
          , Label
              "If these people are allowed to live, these horrors will only repeat themselves. We have to put an end to this. We have to kill them."
              [ story investigatorIds lunacysReward3
              , Record YouSlayedTheMonstersAtTheDinnerParty
              , RecordCount Conviction (conviction + 1)
              , RemoveAllChaosTokens Cultist
              , RemoveAllChaosTokens Tablet
              , RemoveAllChaosTokens ElderThing
              , AddChaosToken Cultist
              , AddChaosToken Cultist
              , NextCampaignStep Nothing
              ]
          ]
      pure c
    CampaignStep (InterludeStep 2 mInterludeKey) -> do
      investigatorIds <- allInvestigatorIds
      leadInvestigatorId <- getLeadInvestigatorId
      conviction <- getRecordCount Conviction
      doubt <- getRecordCount Doubt
      let
        respondToWarning =
          chooseOne
            leadInvestigatorId
            [ Label
                "Possession? Oaths? There must be another explanation for all of this. Proceed to Ignore the Warning."
                [ story investigatorIds ignoreTheWarning
                , Record YouIgnoredDanielsWarning
                , RecordCount Doubt (doubt + 2)
                , NextCampaignStep Nothing
                ]
            , Label
                "We must heed Daniel’s warning. We must not speak the name of the King in Yellow. Proceed to Heed the Warning."
                ( [ story investigatorIds headTheWarning
                  , Record YouHeadedDanielsWarning
                  , RecordCount Conviction (conviction + 2)
                  ]
                    <> map (\iid -> GainXP iid CampaignSource 1) investigatorIds
                    <> [NextCampaignStep Nothing]
                )
            ]
      case mInterludeKey of
        Nothing -> error "Missing key from The Unspeakable Oath"
        Just DanielSurvived -> do
          pushAll $
            [story investigatorIds danielSurvived]
              <> map (\iid -> GainXP iid CampaignSource 2) investigatorIds
              <> [respondToWarning]
        Just DanielDidNotSurvive -> do
          pushAll
            [story investigatorIds danielDidNotSurvive, respondToWarning]
        Just DanielWasPossessed -> do
          pushAll
            [story investigatorIds danielWasPossessed, respondToWarning]
        Just _ -> error "Invalid key for The Unspeakable Oath"
      pure c
    CampaignStep EpilogueStep -> do
      possessed <- getRecordSet Possessed
      let
        investigatorIds = flip mapMaybe possessed $ \case
          SomeRecorded RecordableCardCode (Recorded cardCode) -> Just (InvestigatorId cardCode)
          _ -> Nothing
      pushAll $
        [story investigatorIds epilogue | notNull investigatorIds]
          <> [EndOfGame Nothing]
      pure c
    EnemyDefeated _ cardId _ _ -> do
      card <- getCard cardId
      when (card `cardMatch` cardIs Enemies.theManInThePallidMask) $ do
        n <- getRecordCount ChasingTheStranger
        push (RecordCount ChasingTheStranger (n + 1))
      pure c
    _ -> defaultCampaignRunner msg c
