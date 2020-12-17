{-# LANGUAGE UndecidableInstances #-}

module Arkham.Types.Event.Cards.BindMonster2
  ( bindMonster2
  , BindMonster2(..)
  )
where

import Arkham.Import

import Arkham.Types.Event.Attrs

newtype BindMonster2 = BindMonster2 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

bindMonster2 :: InvestigatorId -> EventId -> BindMonster2
bindMonster2 iid uuid = BindMonster2 $ baseAttrs iid uuid "02031"

ability :: Window -> Target -> Attrs -> Ability
ability window target attrs =
  (mkAbility (toSource attrs) 1 (ReactionAbility window))
    { abilityMetadata = Just (TargetMetadata target)
    }

instance HasActions env BindMonster2 where
  getActions iid window@(WhenWouldReady target) (BindMonster2 attrs@Attrs {..})
    | iid == eventOwner = pure
      [ ActivateCardAbilityAction eventOwner (ability window target attrs)
      | target `elem` eventAttachedTarget
      ]
  getActions iid window (BindMonster2 attrs) = getActions iid window attrs

instance HasModifiersFor env BindMonster2 where
  getModifiersFor = noModifiersFor

instance HasQueue env => RunMessage env BindMonster2 where
  runMessage msg e@(BindMonster2 attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid _ | eid == eventId -> e <$ unshiftMessages
      [ CreateEffect "02031" Nothing (toSource attrs) SkillTestTarget
      , ChooseEvadeEnemy iid (EventSource eid) SkillWillpower False
      ]
    SkillTestEnds -> e <$ when
      (null eventAttachedTarget)
      (unshiftMessage (Discard $ toTarget attrs))
    UseCardAbility iid source _ 1 | isSource attrs source ->
      case eventAttachedTarget of
        Just target -> e <$ unshiftMessage
          (BeginSkillTest iid source target Nothing SkillWillpower 3)
        Nothing -> throwIO $ InvalidState "must be attached"
    PassedSkillTest _ _ source SkillTestInitiatorTarget{} _
      | isSource attrs source -> case eventAttachedTarget of
        Just target@(EnemyTarget _) ->
          e <$ withQueue (\queue -> (filter (/= Ready target) queue, ()))
        _ -> error "invalid target"
    FailedSkillTest _ _ source SkillTestInitiatorTarget{} _
      | isSource attrs source -> e <$ unshiftMessage (Discard $ toTarget attrs)
    _ -> BindMonster2 <$> runMessage msg attrs