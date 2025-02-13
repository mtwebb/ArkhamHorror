<script lang="ts" setup>
import { computed } from 'vue';
import type { Game } from '@/arkham/types/Game';
import StoryQuestion from '@/arkham/components/StoryQuestion.vue';
import Scenario from '@/arkham/components/Scenario.vue';
import UpgradeDeck from '@/arkham/components/UpgradeDeck.vue';

const props = defineProps<{
  game: Game
  investigatorId: string
}>()

const emit = defineEmits<{
  update: [game: Game]
  choose: [idx: number]
}>()

async function update(game: Game) {
  emit('update', game);
}

async function choose(idx: number) {
  emit('choose', idx)
}

const upgradeDeck = computed(() => props.game.campaign && props.game.campaign.step?.tag === 'UpgradeDeckStep')
</script>

<template>
  <div v-if="upgradeDeck" id="game" class="game">
    <UpgradeDeck :game="game" :investigatorId="investigatorId" />
  </div>
  <div v-else-if="game.gameState.tag === 'IsActive'" id="game" class="game">
    <Scenario
      v-if="game.scenario"
      :game="game"
      :scenario="game.scenario"
      :investigatorId="investigatorId"
      @choose="$emit('choose', $event)"
      @update="update"
    />
    <template v-else>
      <StoryQuestion :game="game" :investigatorId="investigatorId" @choose="choose" />
    </template>
  </div>
</template>

<style scoped lang="scss">
.card {
  box-shadow: 0 3px 6px rgba(0,0,0,0.23), 0 3px 6px rgba(0,0,0,0.53);
  border-radius: 6px;
  margin: 2px;
  width: $card-width;
}

.card--sideways {
  width: auto;
  height: $card-width * 2;
}

.scenario-cards {
  display: flex;
  align-self: center;
  align-items: flex-start;
  justify-content: center;
  padding-bottom: 10px;
}

.clue--can-investigate {
  border: 3px solid #ff00ff;
  border-radius: 100px;
  cursor: pointer;
}

.clue {
  position: relative;
  width: 57px;
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: black;
  font-weight: 900;
  font-size: 1.5em;

  img {
    position: absolute;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;
    margin: auto;
    z-index: -1;
  }
}

.game {
  background-image: linear-gradient(darken(#E5EAEC, 10), #E5EAEC);
  width: 100%;
  z-index: 1;
}

.location-cards {
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: auto;
  min-height: 350px;
}

.portrait {
  border-radius: 3px;
}

.portrait--can-move {
  cursor: pointer;
  border: 3px solid $select;
}

.location--can-move-to {
  border: 3px solid $select;
  cursor: pointer;
}

.agenda-container, .act-container {
  align-self: flex-start;
}

.discard {
  height: 100%;
  position: relative;
  &::after {
    pointer-events: none;
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: #FFF;
    /* background-image: linear-gradient(120deg, #eaee44, #33d0ff); */
    opacity: .85;
    mix-blend-mode: saturation;
  }
}
</style>
