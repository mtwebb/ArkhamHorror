module Arkham.Types.Scenario.Scenarios.TheLastKing
  ( TheLastKing(..)
  , theLastKing
  ) where

import Arkham.Prelude

import qualified Arkham.Act.Cards as Acts
import qualified Arkham.Agenda.Cards as Agendas
import qualified Arkham.Asset.Cards as Assets
import qualified Arkham.Enemy.Cards as Enemies
import qualified Arkham.Location.Cards as Locations
import Arkham.Scenarios.TheLastKing.Story
import qualified Arkham.Story.Cards as Story
import Arkham.Types.CampaignLogKey
import Arkham.Types.CampaignStep
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Difficulty
import Arkham.Types.Effect.Window
import Arkham.Types.EffectMetadata
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.Query
import Arkham.Types.Resolution
import Arkham.Types.Scenario.Attrs
import Arkham.Types.Scenario.Helpers
import Arkham.Types.Scenario.Runner
import Arkham.Types.ScenarioLogKey
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Token
import qualified Arkham.Types.Trait as Trait

newtype TheLastKing = TheLastKing ScenarioAttrs
  deriving anyclass IsScenario
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theLastKing :: Difficulty -> TheLastKing
theLastKing difficulty =
  TheLastKing
    $ baseAttrs
        "03061"
        "The Last King"
        [Agendas.fashionablyLate, Agendas.theTerrifyingTruth]
        [Acts.discoveringTheTruth]
        difficulty
    & locationLayoutL
    ?~ [ "diningRoom .         gallery"
       , "ballroom   courtyard livingRoom"
       , ".          foyer     ."
       ]
instance HasRecord TheLastKing where
  hasRecord _ = pure False
  hasRecordSet _ = pure []
  hasRecordCount _ = pure 0

instance
  ( HasCount Shroud env LocationId
  , HasId LocationId env InvestigatorId
  , HasTokenValue env InvestigatorId
  )
  => HasTokenValue env TheLastKing where
  getTokenValue (TheLastKing attrs) iid = \case
    Skull -> pure $ TokenValue Skull NoModifier
    Cultist -> pure $ toTokenValue attrs Cultist 2 3
    Tablet -> pure $ TokenValue Tablet (NegativeModifier 4)
    ElderThing -> do
      lid <- getId @LocationId iid
      shroud <- unShroud <$> getCount lid
      pure $ TokenValue ElderThing (NegativeModifier shroud)
    otherFace -> getTokenValue attrs iid otherFace

standaloneTokens :: [TokenFace]
standaloneTokens =
  [ PlusOne
  , Zero
  , Zero
  , MinusOne
  , MinusOne
  , MinusOne
  , MinusTwo
  , MinusTwo
  , MinusThree
  , MinusFour
  , Skull
  , Skull
  , Skull
  , AutoFail
  , ElderSign
  ]

interviewedToCardCode :: ScenarioLogKey -> Maybe CardCode
interviewedToCardCode = \case
  InterviewedConstance -> Just $ toCardCode Assets.constanceDumaine
  InterviewedJordan -> Just $ toCardCode Assets.jordanPerry
  InterviewedHaruko -> Just $ toCardCode Assets.ishimaruHaruko
  InterviewedSebastien -> Just $ toCardCode Assets.sebastienMoreau
  InterviewedAshleigh -> Just $ toCardCode Assets.ashleighClarke
  _ -> Nothing

instance ScenarioRunner env => RunMessage env TheLastKing where
  runMessage msg s@(TheLastKing attrs) = case msg of
    SetTokensForScenario -> do
      standalone <- getIsStandalone
      randomToken <- sample (Cultist :| [Tablet, ElderThing])
      s <$ if standalone
        then push (SetTokens $ standaloneTokens <> [randomToken, randomToken])
        else pure ()
    StandaloneSetup -> do
      leadInvestigatorId <- getLeadInvestigatorId
      s
        <$ push
             (AddCampaignCardToDeck
               leadInvestigatorId
               Enemies.theManInThePallidMask
             )
    Setup -> do
      encounterDeck <- buildEncounterDeckExcluding
        [Enemies.dianneDevine]
        [EncounterSet.TheLastKing, EncounterSet.AncientEvils]

      foyer <- genCard Locations.foyer
      courtyard <- genCard Locations.courtyard
      livingRoom <- genCard Locations.livingRoom
      ballroom <- genCard Locations.ballroom
      diningRoom <- genCard Locations.diningRoom
      gallery <- genCard Locations.gallery

      totalClues <- getPlayerCountValue (StaticWithPerPlayer 1 1)

      bystanders <- shuffleM =<< traverse
        genCard
        [ Assets.constanceDumaine
        , Assets.jordanPerry
        , Assets.ishimaruHaruko
        , Assets.sebastienMoreau
        , Assets.ashleighClarke
        ]

      destinations <- shuffleM $ map
        toLocationId
        [courtyard, livingRoom, ballroom, diningRoom, gallery]

      investigatorIds <- getInvestigatorIds

      pushAll
        ([ story investigatorIds intro
         , SetEncounterDeck encounterDeck
         , AddAgenda "03062"
         , AddAct "03064"
         , PlaceLocation foyer
         , PlaceLocation courtyard
         , PlaceLocation livingRoom
         , PlaceLocation ballroom
         , PlaceLocation diningRoom
         , PlaceLocation gallery
         , MoveAllTo (toSource attrs) (toLocationId foyer)
         ]
        <> zipWith CreateStoryAssetAt bystanders destinations
        <> map
             ((`PlaceClues` totalClues) . AssetTarget . AssetId . toCardId)
             bystanders
        )

      setAsideEncounterCards <- traverse genCard [Enemies.dianneDevine]

      storyCards <- traverse
        genCard
        [ Story.sickeningReality_65
        , Story.sickeningReality_66
        , Story.sickeningReality_67
        , Story.sickeningReality_68
        , Story.sickeningReality_69
        ]

      TheLastKing <$> runMessage
        msg
        (attrs
        & (setAsideCardsL .~ setAsideEncounterCards)
        & (cardsUnderScenarioReferenceL .~ storyCards)
        )
    ResolveToken _ token iid -> s <$ case token of
      Skull -> push (DrawAnotherToken iid)
      Cultist | isHardExpert attrs -> do
        clueCount <- unClueCount <$> getCount iid
        when (clueCount > 0) (push $ InvestigatorPlaceCluesOnLocation iid 1)

      Tablet | isHardExpert attrs ->
        push
          (InvestigatorAssignDamage iid (TokenEffectSource token) DamageAny 0 1)
      _ -> pure ()
    FailedSkillTest iid _ _ (TokenTarget token) _ _ ->
      s <$ case tokenFace token of
        Skull -> do
          targets <- selectListMap EnemyTarget $ if isEasyStandard attrs
            then EnemyWithTrait Trait.Lunatic
            else EnemyWithMostRemainingHealth $ EnemyWithTrait Trait.Lunatic
          when
            (notNull targets)
            (push $ chooseOrRunOne
              iid
              [ TargetLabel target [PlaceDoom target 1] | target <- targets ]
            )
        Cultist | isEasyStandard attrs -> do
          clueCount <- unClueCount <$> getCount iid
          when (clueCount > 0) (push $ InvestigatorPlaceCluesOnLocation iid 1)
        Tablet | isEasyStandard attrs -> push
          (InvestigatorAssignDamage iid (TokenSource token) DamageAny 0 1)
        ElderThing | isHardExpert attrs ->
          push (InvestigatorAssignDamage iid (TokenSource token) DamageAny 1 0)
        _ -> pure ()
    ResolveStory card | toName card == "Sickening Reality" -> do
      let
        findPair
          | toCardDef card == Story.sickeningReality_65
          = (Assets.constanceDumaine, Enemies.constanceDumaine)
          | toCardDef card == Story.sickeningReality_66
          = (Assets.jordanPerry, Enemies.jordanPerry)
          | toCardDef card == Story.sickeningReality_67
          = (Assets.ishimaruHaruko, Enemies.ishimaruHaruko)
          | toCardDef card == Story.sickeningReality_68
          = (Assets.sebastienMoreau, Enemies.sebastienMoreau)
          | toCardDef card == Story.sickeningReality_69
          = (Assets.ashleighClarke, Enemies.ashleighClarke)
          | otherwise
          = error "Invalid story"
        (asset, enemy) = findPair

      assetId <- fromJustNote "missing" <$> selectOne (assetIs asset)
      enemyCard <- genCard enemy
      lid <- getId @LocationId assetId
      iids <- selectList $ InvestigatorAt $ LocationWithId lid
      clues <- unClueCount <$> getCount assetId
      s <$ pushAll
        ([ InvestigatorAssignDamage
             iid
             (StorySource $ toCardCode card)
             DamageAny
             0
             1
         | iid <- iids
         ]
        <> [ RemoveClues (AssetTarget assetId) clues
           , PlaceClues (LocationTarget lid) clues
           , RemoveFromGame (AssetTarget assetId)
           , CreateEnemyAt enemyCard lid Nothing
           ]
        )
    ResolveStory card -> do
      let
        remember
          | toCardDef card == Story.engramsOath = InterviewedConstance
          | toCardDef card == Story.langneauPerdu = InterviewedJordan
          | toCardDef card == Story.thePattern = InterviewedHaruko
          | toCardDef card == Story.theFirstShow = InterviewedSebastien
          | toCardDef card == Story.aboveAndBelow = InterviewedAshleigh
          | otherwise = error "invalid story"
      s <$ push (Remember remember)
    ScenarioResolution NoResolution -> do
      anyResigned <- notNull <$> select ResignedInvestigator
      s <$ push (ScenarioResolution $ Resolution $ if anyResigned then 1 else 2)
    ScenarioResolution (Resolution n) -> do
      -- Resolution handles XP in a special way, we must divvy up between investigators
      -- evenly and apply, this will have a weird interaction with Hospital Debts so we
      -- want to handle `getXp` in two phases. The first phase will essentially evenly
      -- add XP modifiers to the players in order to have `getXp` resolve "normally"
      investigatorIds <- getInvestigatorIds
      investigatorIdsWithNames <- traverse
        (traverseToSnd getName)
        investigatorIds
      leadInvestigatorId <- getLeadInvestigatorId
      clueCounts <- traverse (fmap unClueCount . getCount)
        =<< getSetList @ActId ()
      vipsSlain <-
        selectListMap toCardCode $ VictoryDisplayCardMatch $ CardWithTrait
          Trait.Lunatic
      let
        interviewed =
          mapMaybe interviewedToCardCode (setToList $ scenarioLog attrs)
        extraXp = ceiling @Double (fromIntegral (sum clueCounts) / 2)
        (assignedXp, remainingXp) = quotRem extraXp (length investigatorIds)
        assignXp amount iid = CreateWindowModifierEffect
          EffectGameWindow
          (EffectModifiers $ toModifiers (toSource attrs) [XPModifier amount])
          (toSource attrs)
          (InvestigatorTarget iid)
      s <$ pushAll
        ([ assignXp assignedXp iid | iid <- investigatorIds ]
        <> [ chooseN
               leadInvestigatorId
               remainingXp
               [ Label
                   ("Choose " <> display name <> " to gain 1 additional XP")
                   [assignXp 1 iid]
               | (iid, name) <- investigatorIdsWithNames
               ]
           ]
        <> [ RecordSet VIPsInterviewed interviewed | notNull interviewed ]
        <> [ RecordSet VIPsSlain vipsSlain | notNull vipsSlain ]
        <> if n == 2 || n == 3
             then
               [ RemoveAllTokens Cultist
               , RemoveAllTokens Tablet
               , RemoveAllTokens ElderThing
               , AddToken Cultist
               , AddToken Tablet
               , AddToken ElderThing
               ]
             else
               []
               <> [ CrossOutRecordSetEntries VIPsInterviewed interviewed
                  | n == 3
                  ]
               <> [ScenarioResolutionStep 1 (Resolution n)]
        )
    ScenarioResolutionStep 1 (Resolution n) -> do
      investigatorIds <- getInvestigatorIds
      gainXp <- map (uncurry GainXP) <$> getXp
      s <$ case n of
        1 ->
          pushAll
            $ [story investigatorIds resolution1]
            <> gainXp
            <> [EndOfGame (Just $ InterludeStep 1)]
        2 ->
          pushAll
            $ [story investigatorIds resolution2]
            <> gainXp
            <> [EndOfGame Nothing]
        3 ->
          pushAll
            $ [story investigatorIds resolution3]
            <> gainXp
            <> [EndOfGame Nothing]
        _ -> error "Invalid resolution"
    _ -> TheLastKing <$> runMessage msg attrs