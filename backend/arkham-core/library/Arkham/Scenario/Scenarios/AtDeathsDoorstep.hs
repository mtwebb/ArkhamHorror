module Arkham.Scenario.Scenarios.AtDeathsDoorstep
  ( AtDeathsDoorstep(..)
  , atDeathsDoorstep
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Action qualified as Action
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.CampaignLog
import Arkham.CampaignLogKey
import Arkham.Campaigns.TheCircleUndone.Helpers
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Helpers.SkillTest
import Arkham.Investigator.Cards qualified as Investigators
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.Scenarios.AtDeathsDoorstep.Story
import Arkham.Source
import Arkham.Target
import Arkham.Token
import Arkham.Trait ( Trait (Spectral) )

newtype AtDeathsDoorstep = AtDeathsDoorstep ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

atDeathsDoorstep :: Difficulty -> AtDeathsDoorstep
atDeathsDoorstep difficulty = scenario
  AtDeathsDoorstep
  "05065"
  "At Death's Doorstep"
  difficulty
  [ ".             .          office         .             ."
  , "billiardsRoom trophyRoom victorianHalls masterBedroom balcony"
  , ".             .          entryHall      .             ."
  ]

instance HasTokenValue AtDeathsDoorstep where
  getTokenValue iid tokenFace (AtDeathsDoorstep attrs) = case tokenFace of
    Skull -> do
      isHaunted <- selectAny $ locationWithInvestigator iid <> HauntedLocation
      pure . uncurry (toTokenValue attrs Skull) $ if isHaunted
        then (1, 2)
        else (3, 4)
    Tablet -> pure $ toTokenValue attrs Tablet 2 3
    ElderThing -> pure $ toTokenValue attrs ElderThing 2 4
    otherFace -> getTokenValue iid otherFace attrs

standaloneTokens :: [TokenFace]
standaloneTokens =
  [ PlusOne
  , Zero
  , Zero
  , MinusOne
  , MinusOne
  , MinusTwo
  , MinusTwo
  , MinusThree
  , MinusFour
  , Skull
  , Skull
  , Tablet
  , ElderThing
  , AutoFail
  , ElderSign
  ]

standaloneCampaignLog :: CampaignLog
standaloneCampaignLog = mkCampaignLog
  { campaignLogRecordedSets = mapFromList
    [ ( MissingPersons
      , [ crossedOut (toCardCode i)
        | i <-
          [ Investigators.gavriellaMizrah
          , Investigators.jeromeDavids
          , Investigators.valentinoRivas
          , Investigators.pennyWhite
          ]
        ]
      )
    ]
  }

instance RunMessage AtDeathsDoorstep where
  runMessage msg s@(AtDeathsDoorstep attrs) = case msg of
    SetTokensForScenario -> do
      whenM getIsStandalone $ push $ SetTokens standaloneTokens
      pure s
    PreScenarioSetup -> do
      iids <- getInvestigatorIds
      pushAll
        [ story iids introPart1
        , story iids introPart2
        , story iids introPart3
        , story iids introPart4
        ]
      pure s
    StandaloneSetup -> do
      pure $ overAttrs (standaloneCampaignLogL .~ standaloneCampaignLog) s
    Setup -> do
      encounterDeck <- buildEncounterDeckExcluding
        [Enemies.josefMeiger]
        [ EncounterSet.AtDeathsDoorstep
        , EncounterSet.SilverTwilightLodge
        , EncounterSet.SpectralPredators
        , EncounterSet.TrappedSpirits
        , EncounterSet.InexorableFate
        , EncounterSet.ChillingCold
        ]

      realmOfDeath <- map EncounterCard
        <$> gatherEncounterSet EncounterSet.RealmOfDeath
      theWatcher <- map EncounterCard
        <$> gatherEncounterSet EncounterSet.TheWatcher

      setAsideCards <- (<> realmOfDeath <> theWatcher) <$> genCards
        [ Enemies.josefMeiger
        , Locations.entryHallSpectral
        , Locations.victorianHallsSpectral
        , Locations.trophyRoomSpectral
        , Locations.billiardsRoomSpectral
        , Locations.masterBedroomSpectral
        , Locations.balconySpectral
        , Locations.officeSpectral
        ]

      agendas <- genCards [Agendas.justiceXI, Agendas.overTheThreshold]
      acts <- genCards
        [Acts.hiddenAgendas, Acts.theSpectralRealm, Acts.escapeTheCage]

      (entryHallId, placeEntryHall) <- placeLocationCard
        Locations.entryHallAtDeathsDoorstep
      (officeId, placeOffice) <- placeLocationCard Locations.office
      (billiardsRoomId, placeBilliardsRoom) <- placeLocationCard
        Locations.billiardsRoom
      (balconyId, placeBalcony) <- placeLocationCard
        Locations.balconyAtDeathsDoorstep
      otherPlacements <- traverse
        placeLocationCard_
        [ Locations.victorianHalls
        , Locations.trophyRoom
        , Locations.masterBedroom
        ]

      missingPersons <- getRecordedCardCodes MissingPersons
      evidenceLeftBehind <- getRecordCount PiecesOfEvidenceWereLeftBehind
      lead <- getLead

      -- We want to distribute the removal of clues evenly. The logic here
      -- tries to batch a group of four and then a smaller group
      let
        noTimes = ceiling (fromIntegral @_ @Double evidenceLeftBehind / 4)
        splitBy4 n | n <= 0 = []
        splitBy4 n | n <= 4 = [n]
        splitBy4 n = 4 : splitBy4 (n - 4)
        removeClues = map
          (\n -> chooseOrRunN
            lead
            n
            [ targetLabel l [RemoveClues (toTarget l) 1]
            | l <- [entryHallId, officeId, billiardsRoomId, balconyId]
            ]
          )
          (splitBy4 noTimes)

      pushAll
        $ [ SetEncounterDeck encounterDeck
          , SetAgendaDeck
          , SetActDeck
          , placeEntryHall
          , placeOffice
          , placeBilliardsRoom
          , placeBalcony
          , MoveAllTo (toSource attrs) entryHallId
          ]
        <> otherPlacements
        <> [ PlaceClues (toTarget entryHallId) 6
           | toCardCode Investigators.gavriellaMizrah `elem` missingPersons
           ]
        <> [ PlaceClues (toTarget officeId) 6
           | toCardCode Investigators.jeromeDavids `elem` missingPersons
           ]
        <> [ PlaceClues (toTarget billiardsRoomId) 6
           | toCardCode Investigators.valentinoRivas `elem` missingPersons
           ]
        <> [ PlaceClues (toTarget balconyId) 6
           | toCardCode Investigators.pennyWhite `elem` missingPersons
           ]
        <> removeClues

      AtDeathsDoorstep <$> runMessage
        msg
        (attrs
        & (setAsideCardsL .~ setAsideCards)
        & (agendaStackL . at 1 ?~ agendas)
        & (actStackL . at 1 ?~ acts)
        )
    FailedSkillTest iid _ _ (TokenTarget token) _ _ -> do
      case tokenFace token of
        Tablet | isEasyStandard attrs -> do
          mAction <- getSkillTestAction
          for_ mAction $ \action ->
            when (action `elem` [Action.Fight, Action.Evade])
              $ runHauntedAbilities iid
        _ -> pure ()
      pure s
    ResolveToken _ Tablet iid | isHardExpert attrs -> do
      mAction <- getSkillTestAction
      for_ mAction $ \action ->
        when (action `elem` [Action.Fight, Action.Evade])
          $ runHauntedAbilities iid
      pure s
    ResolveToken _ ElderThing iid -> do
      isSpectralEnemy <-
        selectAny
        $ EnemyAt (locationWithInvestigator iid)
        <> EnemyWithTrait Spectral
      when isSpectralEnemy $ push $ InvestigatorAssignDamage
        iid
        (TokenEffectSource ElderThing)
        DamageAny
        1
        (if isHardExpert attrs then 1 else 0)
      pure s
    _ -> AtDeathsDoorstep <$> runMessage msg attrs