// Добавляем поддержку крашера ибо прикольно.
// Переопределяет прок. Ктрл клик с расширениями вскода чтобы узнать где
/obj/item/mod/module/magnetic_harness/Initialize(mapload)
	. = ..()
	if(!guns_typecache)
		guns_typecache = typecacheof(list(
			/obj/item/gun/ballistic,
			/obj/item/gun/energy,
			/obj/item/gun/grenadelauncher,
			/obj/item/gun/chem,
			/obj/item/gun/syringe,
			/obj/item/kinetic_crusher,
		))

// MARK: Mirage
///Mirage grenade dispenser - Dispenses grenades that copy the user's appearance.
/obj/item/mod/module/dispenser/mirage
	name = "MOD mirage grenade dispenser module"
	desc = "This module can create mirage grenades at the user's liking. These grenades create holographic copies of the user."
	icon_state = "mirage_grenade"
	cooldown_time = 20 SECONDS
	use_power_cost = DEFAULT_CHARGE_DRAIN * 30
	overlay_state_inactive = "module_mirage_grenade"
	dispense_type = /obj/item/grenade/mirage

/obj/item/mod/module/dispenser/mirage/on_use()
	var/obj/item/grenade/mirage/grenade = ..()
	grenade.preprime(mod.wearer)

/obj/item/grenade/mirage
	name = "mirage grenade"
	desc = "A special device that, when activated, produces a small stray of active mesh in form of a grenade that creates a static copy of the user."
	icon = 'mod_celadon/_storage_icons/icons/items/weapons/grenade.dmi'
	icon_state = "mirage"
	item_state = "flashbang"
	det_time = 3 SECONDS
	/// Mob that threw the grenade.
	var/mob/living/thrower
	var/spawned_mob = /mob/living/simple_animal/hostile/illusion/mirage
	var/spawn_time = 15 SECONDS

/obj/item/mod/module/dispenser/mirage/moving
	dispense_type = /obj/item/grenade/mirage/moving

/obj/item/grenade/mirage/moving
	name = "mirage grenade"
	desc = "A special device that, when activated, produces a small stray of active mesh in form of a grenade that creates a moving copy of the user."
	spawned_mob = /mob/living/simple_animal/hostile/illusion/escape/mirage

/obj/item/grenade/mirage/preprime(mob/user, delayoverride, msg = TRUE, volume = 60)
	. = ..()
	thrower = user

/obj/item/grenade/mirage/prime()
	. = ..()
	do_sparks(rand(3, 6), FALSE, src)
	if(thrower)
		var/mob/living/simple_animal/hostile/illusion/mirage = new spawned_mob(get_turf(src))
		// mirage.speed = thrower.cached_multiplicative_slowdown
		mirage.Copy_Parent(thrower, spawn_time)
	qdel(src)

/mob/living/simple_animal/hostile/illusion/mirage
	AIStatus = AI_OFF
	density = FALSE

/mob/living/simple_animal/hostile/illusion/escape/mirage
	move_to_delay = 2
	retreat_distance = 5
	minimum_distance = 5
	density = FALSE

/mob/living/simple_animal/hostile/illusion/escape/mirage/death(gibbed)
	do_sparks(rand(3, 6), FALSE, src)
	return ..()

/mob/living/simple_animal/hostile/illusion/mirage/death(gibbed)
	do_sparks(rand(3, 6), FALSE, src)
	return ..()


// MARK: DASH
/// Новый модуль дэша. По умолчанию есть в вендоре интеков
/obj/item/mod/module/dash
	name = "MOD D.A.S.H. module"
	desc = "Directional Acceleration Surge Hardware module utilizes magnetized self-recoiling hydraulics \
	to rapidly extend and launch MOD operator forward. Hydraulics quickly recoil back with the help of magnets,\
	which allows for quick consequent charges, but the power drain increases with each one due to ever increasing heat."
	module_type = MODULE_ACTIVE
	complexity = 3
	incompatible_modules = list(/obj/item/mod/module/armor_assist, /obj/item/mod/module/dash)
	var/charge_distance = 8
	var/charge_power = 400
	var/charging = FALSE
	var/charge_windup = 0.2
	var/charge_ready = TRUE
	var/charge_cooldown = 1.5 SECONDS
	var/consequent_charges_count = 0
	COOLDOWN_DECLARE(mod_charge_cooldown)

/obj/item/mod/module/dash/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(charge_ready)
		charge_ready = FALSE
		addtimer(VARSET_CALLBACK(src, charge_ready, TRUE), charge_cooldown)
		start_charge(target)
	else
		to_chat(mod.wearer,span_danger("D.A.S.H. hydraulics are still recoiling back in place!"))

/obj/item/mod/module/dash/proc/start_charge(atom/target)
	if(consequent_charges_count > 0)
		to_chat(mod.wearer,span_danger("D.A.S.H. hydraulics start to heat up, increasing the power waste!"))
	mod.wearer.Shake(15, 15, 1 SECONDS)
	var/obj/effect/temp_visual/decoy/new_decoy = new /obj/effect/temp_visual/decoy(mod.wearer.loc,mod.wearer)
	animate(new_decoy, alpha = 0, color = "#5a5858", transform = matrix()*2, time = 2)
	addtimer(CALLBACK(src,PROC_REF(handle_charge),target), charge_windup SECONDS, TIMER_STOPPABLE)

	if(COOLDOWN_FINISHED(src, mod_charge_cooldown))
		if(consequent_charges_count > 0)
			consequent_charges_count -= 1
		COOLDOWN_START(src, mod_charge_cooldown,10 SECONDS)
	else
		consequent_charges_count += 1
		COOLDOWN_START(src, mod_charge_cooldown,10 SECONDS)
	addtimer(CALLBACK(src,PROC_REF(handle_power_drain)),10 SECONDS)

/obj/item/mod/module/dash/proc/handle_power_drain()
	if(COOLDOWN_FINISHED(src, mod_charge_cooldown))
		if(consequent_charges_count > 0)
			consequent_charges_count -= 1
			// update_steam_particles()
			playsound(src, 'sound/machines/clockcult/steam_whoosh.ogg', 10, TRUE, frequency = 0.5)
			if(consequent_charges_count == 0)
				to_chat(mod.wearer,span_danger("D.A.S.H. returns to ambient temperature."))
				//QDEL_NULL(part_hold)
			else
				to_chat(mod.wearer,span_danger("D.A.S.H. radiators unleash a burst of hot gas, reducing the power waste!"))
		else
			return
	addtimer(CALLBACK(src,PROC_REF(handle_power_drain)),10 SECONDS)

/obj/item/mod/module/dash/proc/handle_charge(atom/target)
	new /obj/effect/temp_visual/mook_dust(get_turf(mod.wearer))
	playsound(src, 'sound/effects/gravhit.ogg', 50)

	charging = TRUE
	var/turf/charge_target = get_turf(target)
	if(!charge_target)
		charging = FALSE
		return

	//Handling range restrictions
	if(get_dist(get_turf(mod.wearer),charge_target) > charge_distance)
		var/actual_charge_distance = get_dist(get_turf(mod.wearer),target) - charge_distance
		walk_to(mod.wearer,charge_target,actual_charge_distance,0.7)
	else
		walk_to(mod.wearer,charge_target,0,0.7)

	drain_power(charge_power*consequent_charges_count,TRUE)
	sleep(get_dist(mod.wearer, charge_target) * 0.7)
	charge_end()

/obj/item/mod/module/dash/proc/charge_end()
	walk(mod.wearer,0)
	charging = FALSE

// /obj/item/mod/module/dash/proc/update_steam_particles()
// 	if(!part_hold)
// 		part_hold = new(mod.wearer, particle_to_spawn, PARTICLE_ATTACH_MOB)
// 	//addtimer(CALLBACK(part_hold,PROC_REF(QDEL_NULL)),10 SECONDS)
/*
/obj/item/mod/module/shock_absorber
	name = "MOD shock absorption module"
	desc = "A module that makes the user resistant to the knockdown inflicted by Stun Batons."
	icon_state = "no_baton"
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/shock_absorber)
	required_slots = list(ITEM_SLOT_BACK|ITEM_SLOT_BELT)

/obj/item/mod/module/shock_absorber/on_part_activation()
	. = ..()
	ADD_TRAIT(mod.wearer, TRAIT_BATON_RESISTANCE, REF(src))
	RegisterSignal(mod.wearer, COMSIG_MOB_BATONED, PROC_REF(mob_batoned))

/obj/item/mod/module/shock_absorber/on_part_deactivation(deleting)
	. = ..()
	REMOVE_TRAIT(mod.wearer, TRAIT_BATON_RESISTANCE, REF(src))
	UnregisterSignal(mod.wearer, COMSIG_MOB_BATONED)

/obj/item/mod/module/shock_absorber/proc/mob_batoned(datum/source)
	SIGNAL_HANDLER
	drain_power(use_power_cost)
	var/datum/effect_system/lightning_spread/sparks = new /datum/effect_system/lightning_spread
	sparks.set_up(number = 5, cardinals_only = TRUE, location = mod.wearer.loc)
	sparks.start()
*/

// MARK: WARP
///Телепорт, то там роллится 3 д4 и на эту дистанцию тепает. Если три одинаковые цифры выпали, то происходит прикол, который игроки должны сами найти.
/obj/item/mod/module/unstable_warp
	name = "MOD Slipstream warp module"
	desc = "The Slipstream program is a unique innovation. The module itself is a miniaturized near-lightspeed drive capable of transporting the user through bluespace with acceptable accuracy.\n\
	The technology is temperamental, at best: nothing smaller than an armored human being can survive and the stress of exposed blink travel,\n\
	and the experience can be traumatic to the user."
	module_type = MODULE_ACTIVE
	complexity = 4
	active_power_cost = DEFAULT_CHARGE_DRAIN * 2
	incompatible_modules = list(/obj/item/mod/module/unstable_warp)
	cooldown_time = 3 SECONDS
	overlay_state_inactive = "inteq_module_light"
	var/turf/old_loc
	use_power_cost = 1000

/obj/item/mod/module/unstable_warp/proc/returnal()
	if(old_loc)
		mod.wearer.forceMove(old_loc)
		to_chat(mod.wearer,span_alert("...What?"))
		return TRUE
	else
		to_chat(mod.wearer,span_userdanger("WHY AM I NOT COMING BACK? WHERE AM I? I NEED GOD'S HELP, PLEASE!"))
		log_admin("Something broke and [mod.wearer] got stuck after using unstable warp module.")
	return FALSE

/obj/item/mod/module/unstable_warp/on_use()
	if (!..())
		return
	var/list/rolls = list(rand(0,4),rand(0,4),rand(0,4))
	if(rolls[1] == rolls[2] && rolls[1] == rolls[3] && rolls[2] == rolls[3])
		var/list/anomalies = list(locate(85,15,1),locate(32,136,1),locate(175,186,1),locate(170,175,1),locate(170,159,1),locate(9,7,1))
		var/turf/T = pick(anomalies)
		var/mob/living/user = mod.wearer
		old_loc = get_turf(user)
		if(T && prob(10))
			var/atom/movable/AM = user.pulling
			if(AM)
				AM.forceMove(T)
			user.forceMove(T)
			if(AM)
				user.start_pulling(AM)
			to_chat(user, span_notice("I blink and find myself in... What is this place?"))
			addtimer(CALLBACK(src,PROC_REF(returnal)),10 SECONDS)
			return
		else
			to_chat(user,span_danger("I feel incredibly good, I didn't warp this time."))
			return
	var/sum = rolls[1]+rolls[2]+rolls[3]
	if(mod.wearer)
		do_teleport(mod.wearer,get_ranged_target_turf(mod.wearer, mod.wearer.dir, sum))
		drain_power(use_power_cost)
		mod.wearer.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1, 150)
	return


//Indexes for the queue
#define WARP_LOC 1
#define WARP_DIR 2
#define WARP_FOOTPRINT 2

/obj/effect/temp_visual/warp
	name = "warp trace"
	// duration = 0.9 SECONDS
	randomdir = FALSE
	duration = 100 SECONDS
	var/mob/living/carbon/mod_wearer

/obj/effect/temp_visual/warp/trail
	duration = 0.9 SECONDS

/obj/item/mod/module/warp
	name = "warp module"
	desc = "При активации переносит пользователя на 125 метров назад."
	// icon_state = "warp"
	module_type = MODULE_USABLE
	idle_power_cost = DEFAULT_CHARGE_DRAIN
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	removable = TRUE
	incompatible_modules = list(/obj/item/mod/module/warp)
	cooldown_time = 10 SECONDS
	var/list/position_queue = list()
	var/list/chaser_queue = list() // basically the same
	var/warp_max_steps = 125
	var/is_warping = FALSE
	var/chase_timer = 3 SECONDS
	var/chase_delay = 0.15 SECONDS
	var/modified_chase_delay
	/// multiplicative
	var/chaser_timer_modifier = 0.7
	// COOLDOWN_DECLARE(mod_warp_cooldown)

/obj/item/mod/module/warp/proc/handle_position()
	SIGNAL_HANDLER
	if(chaser_queue[1][WARP_LOC] == mod.wearer.loc)
		end_chase()
	else
		update_position()

/obj/item/mod/module/warp/proc/update_position()
	if(!isatom(mod.wearer.loc))
		return

	position_queue += list(list(mod.wearer.loc, mod.wearer.dir))

	// Маленько щиткодный способ проявления прошлого шага.

	var/obj/effect/temp_visual/warp/footprint = new /obj/effect/temp_visual/warp(mod.wearer.loc)

	footprint.appearance = mod.wearer.appearance
	footprint.alpha = 0
	footprint.dir = mod.wearer.dir
	footprint.mod_wearer = mod.wearer

	chaser_queue += list(list(mod.wearer.loc, footprint))

	if(chaser_queue.len != 1)
		var/previous_step_num = chaser_queue.len-1
		var/obj/effect/temp_visual/warp/previous_step = chaser_queue[previous_step_num][WARP_FOOTPRINT]
		previous_step.alpha = 225
		animate(previous_step, alpha = 100, time = 0.9 SECONDS)

/obj/item/mod/module/warp/on_use()
	if(!isatom(mod.wearer.loc))
		return
	if(is_warping)
		return
	var/area/A = get_area(mod.wearer.loc)
	if(HAS_TRAIT(mod.wearer, TRAIT_NO_TELEPORT) || (A.area_flags & NOTELEPORT))
		return
	. = ..()
	if(!.)
		return
	position_queue = list()
	chaser_queue = list()
	is_warping = TRUE
	modified_chase_delay = chase_delay

	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED,PROC_REF(update_position))//RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(update_position))
	update_position()
	addtimer(CALLBACK(src,PROC_REF(chase)), chase_timer)

/obj/item/mod/module/warp/proc/chase()
	if(!is_warping)
		end_chase()
		return
	if(!mod.wearer)
		end_chase()
		return
	// Удаление тени и переход на следующий шаг
	var/obj/effect/temp_visual/warp/old_shadow = chaser_queue[1]?[WARP_FOOTPRINT]
	qdel(old_shadow)
	chaser_queue.Cut(1, 2)

	// Действия в новом шагу
	if(!chaser_queue[1]?[WARP_LOC] || !isturf(chaser_queue[1]?[WARP_LOC]))
		return
	if(mod.wearer.loc == chaser_queue[1]?[WARP_LOC])
		end_chase()
		return
	var/obj/effect/temp_visual/warp/temp = chaser_queue[1]?[WARP_FOOTPRINT]
	temp.alpha = 255
	temp.color = "blue"
	modified_chase_delay = chase_delay*chaser_timer_modifier
	// Продолжает цикл через н-ное время
	addtimer(CALLBACK(src,PROC_REF(chase)), modified_chase_delay)

/obj/item/mod/module/warp/proc/end_chase()
	teleport_owner()
	do_teleport_effects()
	clear_positions()

	// position_queue = null
	// chaser_queue = null
	is_warping = FALSE
	modified_chase_delay = chase_delay
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
	COOLDOWN_START(src, cooldown_timer, cooldown_time)

/obj/item/mod/module/warp/proc/clear_positions()
	while(chaser_queue.len)
		var/obj/effect/temp_visual/warp/temp = chaser_queue[1]?[WARP_FOOTPRINT]
		qdel(temp)
		chaser_queue.Cut(1, 2)
	position_queue = list()
	chaser_queue = list()
	// update_position()

/obj/item/mod/module/warp/proc/do_teleport_effects()
	#warn рантаймит?
	var/delta_alpha = round(225 / position_queue.len)
	var/latest_alpha = 225

	while(position_queue.len)
		var/list/data = position_queue[1]
		position_queue.Cut(1, 2)

		if(!data?[WARP_LOC] || !isturf(data?[WARP_LOC]))
			continue

		// var/obj/effect/temp_visual/warp/temp = new /obj/effect/temp_visual/warp(data[WARP_LOC])
		var/obj/effect/temp_visual/warp/trail/temp = new /obj/effect/temp_visual/warp/trail(data[WARP_LOC])
		temp.alpha = latest_alpha
		temp.appearance = mod.wearer.appearance
		temp.dir = data?[WARP_DIR] ? data?[WARP_DIR] : mod.wearer.dir
		latest_alpha -= delta_alpha

		animate(temp, alpha = 0, time = 0.9 SECONDS)
		// QDEL_IN_STOPPABLE(temp, 0.9 SECONDS)
		// addtimer(CALLBACK(temp, PROC_REF(qdel)), 0.95 SECONDS)

/obj/item/mod/module/warp/proc/teleport_owner()
	// +- рабочее
	// while для случая того, что человек может телепортироваться вообще
	while(position_queue.len)// while(position_queue.count)
		// var/list/data = position_queue.dequeue()
		var/list/data = position_queue[1]
		position_queue.Cut(1, 2)

		if(!data?[WARP_LOC])
			continue
		if(!do_teleport(mod.wearer, data[WARP_LOC]))
			continue
		mod.wearer.dir = data?[WARP_DIR] ? data?[WARP_DIR] : mod.wearer.dir
		return
	mod.wearer.balloon_alert(mod.wearer, "ошибка телепортации!")

#undef WARP_LOC
#undef WARP_DIR
#undef WARP_FOOTPRINT

/*
//Indexes for the queue
#define WARP_LOC 1
#define WARP_DIR 2

/obj/effect/temp_visual/warp
	name = "warp trace"
	duration = 0.9 SECONDS
	randomdir = FALSE

/obj/item/mod/module/warp
	name = "warp module"
	desc = "При активации переносит пользователя на 125 метров назад."
	// icon_state = "warp"
	module_type = MODULE_USABLE
	idle_power_cost = DEFAULT_CHARGE_DRAIN
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	removable = TRUE
	incompatible_modules = list(/obj/item/mod/module/warp)
	cooldown_time = 10 SECONDS
	// STATIC_COOLDOWN_DECLARE(cooldown)
	var/list/position_queue = list()
	var/warp_max_steps = 125

/obj/item/mod/module/warp/on_suit_activation()
	position_queue = list() // position_queue = new()
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED,PROC_REF(update_position))//RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(update_position))
	update_position()

/obj/item/mod/module/warp/on_suit_deactivation(deleting = FALSE)
	position_queue = null
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)

/obj/item/mod/module/warp/proc/update_position(mob/user)
	SIGNAL_HANDLER
	if(!isatom(mod.wearer.loc))
		return

	inject_position(mod.wearer.loc)

/obj/item/mod/module/warp/proc/inject_position(atom/new_loc)
	if(!new_loc)
		return
	// var/test = position_queue.len
	#warn не удаляет
	if(position_queue.len >= warp_max_steps)
		position_queue.Cut(1, 2) // position_queue.dequeue()

	position_queue += list(list(new_loc, mod.wearer.dir)) // position_queue.enqueue(list(new_loc, mod.wearer.dir))

/obj/item/mod/module/warp/proc/clear_positions()
	// плохо работает
	position_queue = list() // position_queue = new()
	update_position()

/obj/item/mod/module/warp/proc/do_teleport_effects()
	// не работает
	var/delta_alpha = 1
	#warn рантаймит
	// var/delta_alpha = round(225 / position_queue.len)
	var/latest_alpha = 225

	while(position_queue.len) //while(position_queue.count)
		//var/list/data = position_queue.dequeue()
		var/test = position_queue.len
		var/list/data = position_queue[1]
		position_queue.Cut(1, 2)

		if(!data?[WARP_LOC] || !isturf(data?[WARP_LOC]))
			continue

		var/obj/effect/temp_visual/warp/temp = new /obj/effect/temp_visual/warp(data[WARP_LOC])
		temp.alpha = latest_alpha
		temp.appearance = mod.wearer.appearance
		temp.dir = data?[WARP_DIR] ? data?[WARP_DIR] : mod.wearer.dir
		latest_alpha -= delta_alpha

		animate(temp, alpha = 0, time = 0.9 SECONDS)

/obj/item/mod/module/warp/proc/teleport_owner()
	// +- рабочее
	while(position_queue.len)// while(position_queue.count)
		// var/list/data = position_queue.dequeue()
		var/list/data = position_queue[1]
		position_queue.Cut(1, 2)

		if(!data?[WARP_LOC])
			continue
		if(!do_teleport(mod.wearer, data[WARP_LOC]))
			continue
		mod.wearer.dir = data?[WARP_DIR] ? data?[WARP_DIR] : mod.wearer.dir
		return
	#warn при первом использовании пишет ошибку телепортации, далее, кажется, сохраняет только этот труф
	mod.wearer.balloon_alert(mod.wearer, "ошибка телепортации!")

/obj/item/mod/module/warp/on_use()
	. = ..()
	if(!.)
		return
	/*
	if(!COOLDOWN_FINISHED(src, cooldown))
		mod.wearer.balloon_alert(mod.wearer, "перезарядка!")
		return
	*/
	teleport_owner()
	do_teleport_effects()
	clear_positions()
	// COOLDOWN_START(src, cooldown, 30 SECONDS)

#undef WARP_LOC
#undef WARP_DIR
*/
