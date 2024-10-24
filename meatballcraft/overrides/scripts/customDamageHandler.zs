#reloadable

import crafttweaker.damage.IDamageSource;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityDefinition;
import crafttweaker.entity.IEntityLiving;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.event.EntityLivingUseItemEvent.Start;
import crafttweaker.event.EntityLivingAttackedEvent;
import crafttweaker.event.EntityLivingDamageEvent;
import crafttweaker.event.EntityLivingExtendedSpawnEvent;
import crafttweaker.event.EntityLivingUpdateEvent;
import crafttweaker.event.LivingKnockBackEvent;
import crafttweaker.player.IPlayer;

/**
 * A list of players who are immune to various forms of damage, knockback, and
 * entity targeting.
 *
 * Specified by their account UUID (preferred but doesn't work in offline mode)
 * or name (can be spoofed in offline mode).
 */
global playerUUIDWhitelist as string[] = [
    "17636f60-afd3-4b0a-aac2-d484aede2420" //-- glektarssza
];

global entitySpawnBlacklist as IEntityDefinition[] = [
    <entity:divinerpg:pumpkin_spider>
];

/**
 * Check if an entity is targeting any player.
 *
 * @param entity The entity to check.
 *
 * @returns `true` if the entity is targeting any player; `false` otherwise.
 */
function isTargetingAnyPlayer(entity as IEntityLiving) as bool {
    return entity.attackTarget instanceof IPlayer || entity.revengeTarget instanceof IPlayer;
}

/**
 * Get the player that an entity is targeting.
 *
 * @param entity The entity to get the targeted player from.
 /
 * @returns The player that the entity is targeting; `null` if none.
 */
function getTargetedPlayer(entity as IEntityLiving) as IPlayer {
    if (entity.attackTarget instanceof IPlayer) {
        return entity.attackTarget;
    } else if (entity.revengeTarget instanceof IPlayer) {
        return entity.revengeTarget;
    }
    return null;
}

/**
 * Check if a player is immune to damage, knockback, and entity targeting.
 *
 * @param player The player to check.
 *
 * @returns `true` if the player is immune; `false` otherwise.
 */
function isPlayerImmune(player as IPlayer) as bool {
    return playerUUIDWhitelist has player.uuid || playerUUIDWhitelist has player.name;
}

/**
 * Check if a damage source is from a player.
 *
 * @param source The damage source to check.
 *
 * @returns `true` if the damage source is from a player; `false` otherwise.
 */
function isDamageSourceFromPlayer(source as IDamageSource) as bool {
    return source.immediateSource instanceof IPlayer || source.trueSource instanceof IPlayer;
}

/**
 * Get a player from a damage source.
 *
 * @param source The damage source to get a player from.
 *
 * @returns The player from the damage source; `null` if none.
 */
function getPlayerFromDamageSource(source as IDamageSource) as IPlayer {
    if (source.immediateSource instanceof IPlayer) {
        return source.immediateSource;
    } else if (source.trueSource instanceof IPlayer) {
        return source.trueSource;
    }
    return null;
}

/**
 * Check if a damage source is from a living entity.
 *
 * @param source The damage source to check.
 *
 * @returns `true` if the damage source is from a living entity; `false` otherwise.
 */
function isDamageSourceFromEntityLiving(source as IDamageSource) as bool {
    return source.immediateSource instanceof IEntityLiving || source.trueSource instanceof IEntityLiving;
}

/**
 * Get the living entity from a damage source.
 *
 * @param source The damage source to get the living entity from.
 *
 * @returns The living entity from the damage source; `null` if none.
 */
function getEntityLivingFromDamageSource(source as IDamageSource) as IEntityLiving {
    if (source.immediateSource instanceof IEntityLiving) {
        return source.immediateSource;
    } else if (source.trueSource instanceof IEntityLiving) {
        return source.trueSource;
    }
    return null;
}

/**
 * Reset the attack data of a living entity.
 *
 * @param entity The entity to reset the attack data of.
 */
function resetAttackData(entity as IEntityLiving) as void {
    //-- No operation
}

//-- Handle entities trying to spawn events
//-- This should prevent Pumpkin Spiders from spawning
events.onCheckSpawn(function(event as EntityLivingExtendedSpawnEvent) {
    var shouldCancel = false;
    var entityDefinition as IEntityDefinition = event.entity.definition;
    if (entitySpawnBlacklist has entityDefinition) {
        //-- lol, no you don't
        shouldCancel = true;
    }
    if (shouldCancel) {
        event.deny();
    } else {
        event.pass();
    }
});

//-- Handle living entity update events
//-- This should prevent mobs from targeting players in most cases during normal gameplay
events.onEntityLivingUpdate(function(event as EntityLivingUpdateEvent) {
    var shouldCancel = false;
    var entityKilled = false;
    var entityDefinition as IEntityDefinition = event.entity.definition;
    if (entitySpawnBlacklist has entityDefinition) {
        //-- Uhhh, how did you get here? Go away, nobody likes you...
        event.entity.setDead();
        entityKilled = true;
    }
    if (event.entity instanceof IEntityLiving && !entityKilled) {
        var entityLiving as IEntityLiving = event.entity;
        if (isTargetingAnyPlayer(entityLiving)) {
            var player as IPlayer = getTargetedPlayer(entityLiving);
            if (isPlayerImmune(player)) {
                //-- lol, no you don't
                resetAttackData(entityLiving);
                shouldCancel = false;
            }
        }
    }
    // NOTE: This doesn't stop ranged mobs from targeting you...
    // NOTE: Hostile mobs still attack if you're inside their melee attack range occassionally if you attack first
    // QUESTION: Can we event stop that?
    if (shouldCancel) {
        event.cancel();
    }
});

//-- Handle living entities being damaged events
//-- This should prevent players from taking damage from most sources and reset targeting data on entities who target them in those cases
events.onEntityLivingDamage(function(event as EntityLivingDamageEvent) {
    var shouldCancel = false;
    if (event.entity instanceof IPlayer) {
        var player as IPlayer = event.entity;
        if (isPlayerImmune(player)) {
            if (isDamageSourceFromEntityLiving(event.damageSource)) {
                //-- lol, no you REALLY don't
                var entityLiving as IEntityLiving = getEntityLivingFromDamageSource(event.damageSource);
                resetAttackData(entityLiving);
                shouldCancel = true;
            }
            if (event.damageSource.fireDamage) {
                //-- lol, no you REALLY don't
                shouldCancel = true;
            }
            if (event.damageSource.magicDamage) {
                //-- lol, no you REALLY don't
                shouldCancel = true;
            }
            if (event.damageSource.explosion) {
                //-- lol, no you REALLY don't
                shouldCancel = true;
            }
            // TODO: Figure out other damage types here
        }
    }
    if (shouldCancel) {
        event.cancel();
    }
});

//-- Handle living entities being knocked back events
//-- This should prevent players from being knocked back by most sources
// NOTE: This one might be broken right now...
events.onLivingKnockBack(function(event as LivingKnockBackEvent) {
    var shouldCancel = false;
    if (event.entity instanceof IPlayer) {
        var player as IPlayer = event.entity;
        if (isPlayerImmune(player)) {
            //-- lol, no you REALLY don't
            event.strength = 0.0;
            shouldCancel = true;
        }
    }
    if (shouldCancel) {
        event.cancel();
    }
});

//-- Handle living entities being attacked events
//-- This should prevent entities from registering players as targets after being attacked by them in most cases
events.onEntityLivingAttacked(function(event as EntityLivingAttackedEvent) {
    var shouldCancel = false;
    if (isDamageSourceFromPlayer(event.damageSource)) {
        if (event.entity instanceof IEntityLiving) {
            var player as IPlayer = getPlayerFromDamageSource(event.damageSource);
            if (isPlayerImmune(player)) {
                var entityLiving as IEntityLiving = event.entity;
                //-- lol, no you don't
                resetAttackData(entityLiving);
            }
        }
    }
    if (shouldCancel) {
        event.cancel();
    }
});

//-- Handle living entities starting to use an item events
//-- This should prevent entities from targeting players when using ranged attacks in most cases
events.onEntityLivingUseItemStart(function(event as Start) {
    var shouldCancel = false;
    if (event.entity instanceof IEntityLiving) {
        var entityLiving as IEntityLiving = event.entity;
        if (isTargetingAnyPlayer(entityLiving)) {
            var player = getTargetedPlayer(entityLiving);
            if (isPlayerImmune(player)) {
                // -- lol, no you don't
                resetAttackData(entityLiving);
                shouldCancel = true;
            }
        }
    }
    if (shouldCancel) {
        event.cancel();
    }
});
