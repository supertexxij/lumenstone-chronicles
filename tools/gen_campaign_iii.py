#!/usr/bin/env python3
"""Generate Campaign III (Weeks 19-27) for Lumenstone Godot."""
import json
from pathlib import Path

ROOT = Path("/workspace/lumenstone-godot/data")

def mc(pid, prompt, options, answer):
    return {"id": pid, "prompt": prompt, "type": "multiple-choice", "options": options, "answer": answer}

def tf(pid, prompt, answer="True"):
    return {"id": pid, "prompt": prompt, "type": "true-false", "options": ["True", "False"], "answer": answer}

def fb(pid, prompt, answer):
    return {"id": pid, "prompt": prompt, "type": "fill-blank", "answer": answer}

def quest(qid, title, week, day, guild, subject, hook, dialogue, challenges, item, xp=20, bonus=None):
    return {
        "id": qid, "title": title, "week": week, "day": day, "guild": guild,
        "subject_label": subject, "hook": hook, "dialogue": dialogue,
        "challenges": challenges, "xp_reward": xp, "lumen_on_mastery": True,
        "unlock_item_id": item, "bonus_items": bonus or [],
    }

def dlg(speaker, text):
    return {"speaker": speaker, "text": text}

quests = []
items = {}

def add_item(iid, name, desc, slot, color, unlock_quest):
    items[iid] = {
        "id": iid, "name": name, "description": desc, "slot": slot,
        "color": color, "unlock_quest_id": unlock_quest,
    }

SB, MB, MS, SC, CK, HS = (
    "Steward Guide", "Master Builder", "Master Scribe",
    "Steward of Creation", "Chronicle Keeper", "High Steward",
)

# ========== WEEK 19 ==========
quests.append(quest(
    "w19-bible-orderliness", "Lights for Seasons", 19, 1, "bible",
    "Bible — Genesis 1:14–18 & Orderliness",
    "\"God set lights in the sky for signs, seasons, days, and years.\"",
    [dlg(SB, "Genesis 1:14–18: the sun, moon, and stars are created lights — not gods to worship."),
     dlg(SB, "Virtue: Orderliness. The High King orders days and nights wisely.")],
    [mc("w19b1", "Genesis 1:14–18 teaches that sun, moon, and stars are…",
        ["created lights for signs and seasons", "gods to worship", "accidents only", "forbidden to study"],
        "created lights for signs and seasons"),
     mc("w19b2", "God made lights to mark…",
        ["signs, seasons, days, and years", "only taxes", "only maps of Texas", "nothing useful"],
        "signs, seasons, days, and years"),
     mc("w19b3", "Orderliness means…",
        ["keeping things in wise, careful order", "making a mess on purpose", "never measuring", "ignoring seasons"],
        "keeping things in wise, careful order"),
     tf("w19b4", "True or False: Christians thank God for ordered days and nights."),
     mc("w19b5", "We study the sky with wonder because…",
        ["the Creator made it with purpose", "we worship the sun", "stars decide our luck", "light is random chaos"],
        "the Creator made it with purpose")],
    "orderliness_band", 10))
add_item("orderliness_band", "Orderliness Band", "A simple band recalling Genesis lights and orderly habits.", "accessory", "#c9b037", "w19-bible-orderliness")

quests.append(quest(
    "w19-math-length", "Yardstick of the Realm", 19, 2, "math",
    "Math — Customary Length (in, ft, yd)",
    "\"Estimate, then measure — inches, feet, and yards build the realm.\"",
    [dlg(MB, "12 inches = 1 foot. 3 feet = 1 yard. Estimate first, then check with a yardstick."),
     dlg(MB, "Builders of the Republic measure carefully for honest work.")],
    [fb("w19m1", "12 inches = ____ foot/feet", "1"),
     fb("w19m2", "3 feet = ____ yard(s)", "1"),
     fb("w19m3", "36 inches = ____ yard(s)", "1"),
     fb("w19m4", "2 feet = ____ inches", "24"),
     mc("w19m5", "A door is about 7 feet tall. About how many yards?",
        ["a little more than 2 yards", "7 yards", "1 inch", "36 yards"], "a little more than 2 yards"),
     mc("w19m6", "Which unit best measures a pencil?", ["inches", "miles", "yards only", "tons"], "inches"),
     fb("w19m7", "5 yards = ____ feet", "15"),
     tf("w19m8", "True or False: Estimating before measuring is a wise builder habit.")],
    "realm_yardstick", 12))
add_item("realm_yardstick", "Realm Yardstick", "A marked stick for inches, feet, and yards.", "belt", "#8b6914", "w19-math-length")

quests.append(quest(
    "w19-la-research", "Note Cards of the Hall", 19, 3, "la",
    "LA — Research Notes & Spelling tion/sion",
    "\"Gather facts on note cards; spell -tion and -sion with care.\"",
    [dlg(MS, "Research starts with questions, trusted sources, and short notes — not copying whole pages."),
     dlg(MS, "Watch endings: nation, mission, vision. Spelling patterns help you write clearly.")],
    [mc("w19l1", "A good research note card should hold…",
        ["short facts in your own words plus the source", "an entire copied chapter", "only doodles", "no topic at all"],
        "short facts in your own words plus the source"),
     mc("w19l2", "Which word ends with -tion?", ["nation", "run", "map", "inch"], "nation"),
     mc("w19l3", "Which word ends with -sion?", ["mission", "cat", "inch", "Houston"], "mission"),
     mc("w19l4", "Before writing a report you should…",
        ["gather notes from trusted sources", "guess every fact", "skip reading", "never ask a question"],
        "gather notes from trusted sources"),
     tf("w19l5", "True or False: Copying a whole page without thinking is good research.", "False"),
     mc("w19l6", "Spelling tip: many -tion words sound like…",
        ["shun at the end", "only long a", "silent forever", "a Texas river"], "shun at the end")],
    "research_notecards", 10))
add_item("research_notecards", "Research Notecards", "Blank cards for short research notes and sources.", "accessory", "#3a6ea5", "w19-la-research")

quests.append(quest(
    "w19-science-solar", "Created Order of the Heavens", 19, 4, "science",
    "Science — Solar System as Created Order",
    "\"The sun gives light and heat; planets travel ordered paths — wonder, not worship.\"",
    [dlg(SC, "Our solar system shows created order: the sun lights and warms Earth; planets follow paths."),
     dlg(SC, "We study creation with gratitude. We do not worship the sun or stars.")],
    [mc("w19s1", "The sun is mainly a source of…",
        ["light and heat for Earth", "voting ballots", "fraction tiles", "mission bells only"],
        "light and heat for Earth"),
     mc("w19s2", "Earth is a…",
        ["planet that orbits the sun", "star we live inside", "moon of Jupiter only", "random cloud"],
        "planet that orbits the sun"),
     tf("w19s3", "True or False: Christians may study the solar system as God's ordered design."),
     mc("w19s4", "We should…",
        ["thank the Creator and not worship created lights", "pray to the sun", "ignore the sky", "call planets gods"],
        "thank the Creator and not worship created lights"),
     mc("w19s5", "The moon…",
        ["orbits Earth and reflects sunlight", "is our sun", "makes fractions", "votes for presidents"],
        "orbits Earth and reflects sunlight"),
     mc("w19s6", "Order in the heavens points to…",
        ["a wise Creator", "pure chaos only", "human taxes", "a spelling rule"], "a wise Creator")],
    "solar_order_chart", 10))
add_item("solar_order_chart", "Solar Order Chart", "A simple chart of sun, Earth, and moon as created lights.", "accessory", "#2d6a4f", "w19-science-solar")

quests.append(quest(
    "w19-history-republic", "Republic of Texas Hall", 19, 5, "history",
    "History — Republic of Texas & Houston",
    "\"After San Jacinto, Texas stood as a republic; leaders like Houston served the people.\"",
    [dlg(CK, "The Republic of Texas (1836–1845) was its own nation before statehood."),
     dlg(CK, "Sam Houston was a key leader — imperfect, but important in Texas history.")],
    [mc("w19h1", "The Republic of Texas began after…",
        ["winning independence (San Jacinto era)", "becoming a US state first", "the moon landing", "World War II"],
        "winning independence (San Jacinto era)"),
     mc("w19h2", "Sam Houston is remembered as…",
        ["a major Republic of Texas leader", "a planet", "a fraction", "a Spanish king only"],
        "a major Republic of Texas leader"),
     mc("w19h3", "A republic is a form of government where…",
        ["leaders represent the people under law", "one planet rules Earth", "no laws exist", "only yards are measured"],
        "leaders represent the people under law"),
     tf("w19h4", "True or False: Texas was a republic before it became a US state."),
     mc("w19h5", "Republic years were roughly…",
        ["1836 to 1845", "1492 only", "2000–2005", "Day 1 of Creation only"], "1836 to 1845"),
     mc("w19h6", "Learning leaders' stories helps us…",
        ["understand courage, mistakes, and service", "worship politicians", "skip maps", "ignore virtue"],
        "understand courage, mistakes, and service")],
    "houston_pin", 10))
add_item("houston_pin", "Houston Pin", "A pin recalling Republic leaders and service.", "accessory", "#9b2226", "w19-history-republic")

quests.append(quest(
    "w19-raid-review", "Raid Review: Yardstick of the Realm", 19, 5, "math",
    "Friday Raid — Week 19 Mixed Review",
    "\"Prove length, research notes, solar order, Republic Texas, Genesis lights.\"",
    [dlg(HS, "Week 19 proving. Mastery ≥80%."),
     dlg(HS, "Measure honestly; order your notes; thank God for ordered skies.")],
    [fb("w19r1", "3 feet = ____ yard(s)", "1"),
     fb("w19r2", "24 inches = ____ feet", "2"),
     mc("w19r3", "Good research notes are…",
        ["short facts in your own words", "whole copied books", "blank forever", "only combat scores"],
        "short facts in your own words"),
     mc("w19r4", "The sun provides Earth with…",
        ["light and heat", "voting booths", "empresario contracts", "soft c rules"], "light and heat"),
     mc("w19r5", "Republic of Texas leader often named…",
        ["Sam Houston", "Neptune", "a yardstick", "Paul Revere only"], "Sam Houston"),
     mc("w19r6", "Genesis 1:14–18: lights are for…",
        ["signs and seasons", "luck charms", "tax rates", "only poetry"], "signs and seasons"),
     tf("w19r7", "True or False: We worship the sun as a deity.", "False"),
     fb("w19r8", "12 inches = ____ foot", "1")],
    "yardstick_cloak", 30))
add_item("yardstick_cloak", "Yardstick Cloak", "Cloak earned at the Yardstick of the Realm raid review.", "cape", "#8b6914", "w19-raid-review")

# ========== WEEK 20 ==========
quests.append(quest(
    "w20-bible-excellence", "Work Heartily", 20, 1, "bible",
    "Bible — Colossians 3:23 & Excellence",
    "\"Whatever you do, work heartily, as for the Lord.\"",
    [dlg(SB, "Colossians 3:23: do your work as if serving the Lord — that is excellence."),
     dlg(SB, "Virtue: Excellence. Careful measuring and careful words honor Him.")],
    [mc("w20b1", "Colossians 3:23 says work…",
        ["heartily, as for the Lord", "lazily for no one", "only when watched", "never at home"],
        "heartily, as for the Lord"),
     mc("w20b2", "Excellence means…",
        ["doing your best with care and honesty", "showing off cruelly", "skipping hard parts", "cheating for a high score"],
        "doing your best with care and honesty"),
     tf("w20b3", "True or False: Small chores can be done for the Lord."),
     mc("w20b4", "Working as for the Lord helps us…",
        ["try carefully even when no one sees", "quit early", "mock others", "hate practice"],
        "try carefully even when no one sees"),
     mc("w20b5", "Who wrote Colossians?", ["Paul", "Sam Houston", "a moon phase", "Newton only"], "Paul")],
    "excellence_seal", 10))
add_item("excellence_seal", "Excellence Seal", "A seal reminding apprentices to work heartily.", "accessory", "#c9a227", "w20-bible-excellence")

quests.append(quest(
    "w20-math-weight-capacity", "Scales & Measures", 20, 2, "math",
    "Math — Weight (oz, lb) & Capacity (c, pt, qt, gal)",
    "\"Weigh with ounces and pounds; pour with cups, pints, quarts, and gallons.\"",
    [dlg(MB, "16 ounces = 1 pound. Capacity: 2 cups = 1 pint; 2 pints = 1 quart; 4 quarts = 1 gallon."),
     dlg(MB, "Use real kitchen tools when you can — excellence in practice.")],
    [fb("w20m1", "16 ounces = ____ pound(s)", "1"),
     fb("w20m2", "2 cups = ____ pint(s)", "1"),
     fb("w20m3", "2 pints = ____ quart(s)", "1"),
     fb("w20m4", "4 quarts = ____ gallon(s)", "1"),
     mc("w20m5", "A bag of flour might be measured in…", ["pounds", "miles", "degrees only", "years"], "pounds"),
     mc("w20m6", "Milk in a jug is often sold by the…", ["gallon", "inch", "planet", "verse"], "gallon"),
     fb("w20m7", "32 ounces = ____ pounds", "2"),
     tf("w20m8", "True or False: 1 gallon holds more than 1 quart.")],
    "balance_scale", 12))
add_item("balance_scale", "Balance Scale", "A scale for ounces, pounds, and careful weighing.", "belt", "#6c757d", "w20-math-weight-capacity")

quests.append(quest(
    "w20-la-essay", "Three Paragraph Scaffold", 20, 3, "la",
    "LA — 3-Paragraph Informational Essay & Linking Words",
    "\"Introduction, body, conclusion — link ideas with clear words.\"",
    [dlg(MS, "A three-paragraph essay: open with a topic, explain with facts, close by restating the big idea."),
     dlg(MS, "Linking words: first, next, also, for example, finally — help readers follow.")],
    [mc("w20l1", "A three-paragraph informational essay usually has…",
        ["introduction, body, conclusion", "only jokes", "only a title", "combat logs"],
        "introduction, body, conclusion"),
     mc("w20l2", "Which is a linking word?", ["finally", "zxq", "punch", "wisp"], "finally"),
     mc("w20l3", "The introduction should…",
        ["state the topic clearly", "end the essay", "list only ounces", "ignore the reader"],
        "state the topic clearly"),
     tf("w20l4", "True or False: The conclusion may restate the main idea."),
     mc("w20l5", "For example is useful to…",
        ["give a supporting detail", "erase the topic", "start a war", "measure gallons only"],
        "give a supporting detail"),
     mc("w20l6", "Informational writing should be…",
        ["clear and factual", "only secret codes", "always fiction", "never revised"],
        "clear and factual")],
    "essay_scaffold", 10))
add_item("essay_scaffold", "Essay Scaffold", "A three-box outline for intro, body, and conclusion.", "accessory", "#3a6ea5", "w20-la-essay")

quests.append(quest(
    "w20-science-moon", "Moon Phase Chart", 20, 4, "science",
    "Science — Moon Phases Observation",
    "\"Watch the moon's changing shape — light and shadow in created order.\"",
    [dlg(SC, "Moon phases show how much of the sunlit side we see from Earth over about a month."),
     dlg(SC, "Start a 2-week chart: sketch the shape and date each clear night.")],
    [mc("w20s1", "Moon phases change because…",
        ["we see different amounts of the sunlit side", "the moon turns into cheese", "Texas votes on it", "fractions melt"],
        "we see different amounts of the sunlit side"),
     mc("w20s2", "A full moon looks…",
        ["fully lit and round", "completely invisible always", "square", "like a gallon jug"],
        "fully lit and round"),
     mc("w20s3", "A new moon is…",
        ["mostly not visible (dark to us)", "the sun itself", "a US state", "a spelling pattern"],
        "mostly not visible (dark to us)"),
     tf("w20s4", "True or False: Observing the moon with a dated sketch is good science stewardship."),
     mc("w20s5", "The moon's light at night is mostly…",
        ["reflected sunlight", "fireflies only", "electric lamps on the moon", "lava"],
        "reflected sunlight"),
     mc("w20s6", "Phases happen in…",
        ["a repeating order over weeks", "random chaos daily with no pattern", "only leap years", "math class alone"],
        "a repeating order over weeks")],
    "moon_phase_wheel", 10))
add_item("moon_phase_wheel", "Moon Phase Wheel", "A wheel chart for tracking moon shapes over nights.", "accessory", "#adb5bd", "w20-science-moon")

quests.append(quest(
    "w20-history-statehood", "Texas Joins the Union", 20, 5, "history",
    "History — Texas Statehood 1845",
    "\"In 1845 Texas became a state of the United States — update your map.\"",
    [dlg(CK, "Texas statehood came in 1845. The lone star joined the growing United States."),
     dlg(CK, "Update your US map: Texas is a large state in the south-central region.")],
    [mc("w20h1", "Texas became a US state in…", ["1845", "1776", "1492", "2001"], "1845"),
     mc("w20h2", "Before statehood, Texas was a…", ["republic", "planet", "gallon", "constellation"], "republic"),
     tf("w20h3", "True or False: Statehood means Texas became part of the United States."),
     mc("w20h4", "On a US map, Texas is in the…",
        ["south-central area", "far northeast only", "Alaska region", "ocean only"], "south-central area"),
     mc("w20h5", "The Lone Star reminds us of…",
        ["Texas identity and history", "a moon deity", "a cup measure", "random chance"],
        "Texas identity and history"),
     mc("w20h6", "Learning statehood helps us…",
        ["see how the nation grew", "skip geography", "worship maps", "ignore dates"],
        "see how the nation grew")],
    "statehood_star", 10))
add_item("statehood_star", "Statehood Star", "A lone-star token for Texas joining the Union in 1845.", "accessory", "#bf1e2e", "w20-history-statehood")

quests.append(quest(
    "w20-raid-review", "Raid Review: Scales & Measures", 20, 5, "math",
    "Friday Raid — Week 20 Mixed Review",
    "\"Prove weight/capacity, essay parts, moon phases, 1845 statehood, Colossians 3:23.\"",
    [dlg(HS, "Week 20 proving. Mastery ≥80%."),
     dlg(HS, "Work heartily — measure, write, and observe with excellence.")],
    [fb("w20r1", "16 oz = ____ lb", "1"),
     fb("w20r2", "4 quarts = ____ gallon", "1"),
     mc("w20r3", "Essay middle paragraph is often the…",
        ["body with facts", "only title", "raid boss", "moon worship"], "body with facts"),
     mc("w20r4", "Moon phases show…",
        ["changing sunlit side we see", "Texas taxes", "spelling only", "random chaos with no pattern"],
        "changing sunlit side we see"),
     mc("w20r5", "Texas statehood year?", ["1845", "1836 only forever", "1620", "1914"], "1845"),
     mc("w20r6", "Colossians 3:23: work…",
        ["as for the Lord", "only for praise of crowds", "never", "for luck charms"], "as for the Lord"),
     tf("w20r7", "True or False: 2 cups = 1 pint."),
     fb("w20r8", "2 pints = ____ quart(s)", "1")],
    "scales_cloak", 30))
add_item("scales_cloak", "Scales Cloak", "Cloak earned at the Scales & Measures raid review.", "cape", "#6c757d", "w20-raid-review")

# ========== WEEK 21 ==========
quests.append(quest(
    "w21-bible-humility-psalm8", "How Majestic Is Your Name", 21, 1, "bible",
    "Bible — Psalm 8:3–4 & Humility",
    "\"When I look at your heavens… what is man that you are mindful of him?\"",
    [dlg(SB, "Psalm 8:3–4: the night sky makes us small — and loved — before God."),
     dlg(SB, "Virtue: Humility. Wonder at creation without pride.")],
    [mc("w21b1", "Psalm 8 marvels at God's…",
        ["heavens and care for people", "tax code", "only polygons", "combat XP"],
        "heavens and care for people"),
     mc("w21b2", "Humility before creation means…",
        ["praising God, not ourselves", "boasting we made the stars", "ignoring the sky", "worshiping planets"],
        "praising God, not ourselves"),
     tf("w21b3", "True or False: People are small compared to the heavens, yet God cares for us."),
     mc("w21b4", "Psalm 8 teaches us to…",
        ["worship the Creator with awe", "worship the moon", "mock small children", "hate science"],
        "worship the Creator with awe"),
     mc("w21b5", "Looking at stars should lead to…",
        ["thankful humility", "pride that we are gods", "fear of luck charms", "skipping Bible"],
        "thankful humility")],
    "psalm8_band", 10))
add_item("psalm8_band", "Psalm 8 Band", "A band for humility under the night heavens.", "accessory", "#6a4c93", "w21-bible-humility-psalm8")

quests.append(quest(
    "w21-math-geometry", "Geometry Gardens", 21, 2, "math",
    "Math — Shapes, Angles, Perimeter",
    "\"Polygons, right angles, and perimeter — fence the garden wisely.\"",
    [dlg(MB, "A polygon has straight sides. A right angle is like a square corner. Perimeter is the distance around."),
     dlg(MB, "Add all side lengths to find perimeter.")],
    [fb("w21m1", "A square has ____ equal sides", "4"),
     fb("w21m2", "A triangle has ____ sides", "3"),
     fb("w21m3", "Perimeter of a 3 by 5 rectangle (units)?", "16"),
     mc("w21m4", "A right angle measures…", ["90 degrees", "1 degree", "360 inches", "1845"], "90 degrees"),
     fb("w21m5", "A pentagon has ____ sides", "5"),
     mc("w21m6", "Perimeter means…",
        ["distance around a shape", "space inside only", "weight in pounds", "a moon phase"],
        "distance around a shape"),
     tf("w21m7", "True or False: A circle is a polygon.", "False"),
     fb("w21m8", "Sides 4+4+4+4 for a square: perimeter =", "16")],
    "geometry_set", 12))
add_item("geometry_set", "Geometry Set", "Shapes and a corner square for angles and perimeter.", "belt", "#d4a017", "w21-math-geometry")

quests.append(quest(
    "w21-la-adverbs", "Adverbs & Dialogue Paths", 21, 3, "la",
    "LA — Adverbs, Dialogue, Plural Spelling",
    "\"Adverbs tell how; dialogue needs quotes; plurals follow patterns.\"",
    [dlg(MS, "Adverbs often tell how, when, or where — many end in -ly (carefully, quickly)."),
     dlg(MS, "Dialogue needs quotation marks. Watch plural rules: box→boxes, baby→babies.")],
    [mc("w21l1", "Which word is an adverb?", ["carefully", "stone", "Houston", "gallon"], "carefully"),
     mc("w21l2", "Adverbs often answer…",
        ["how, when, or where", "only who owns Texas", "square root luck", "nothing"],
        "how, when, or where"),
     mc("w21l3", "Correct dialogue style uses…",
        ["quotation marks around spoken words", "no marks ever", "only numbers", "combat hitsplats"],
        "quotation marks around spoken words"),
     mc("w21l4", "Plural of box is…", ["boxes", "boxs", "boxies", "boxen"], "boxes"),
     mc("w21l5", "Plural of baby is…", ["babies", "babys", "babyes", "babe"], "babies"),
     tf("w21l6", "True or False: Said is a common dialogue tag.")],
    "adverb_ribbon", 10))
add_item("adverb_ribbon", "Adverb Ribbon", "A ribbon for how/when/where words and dialogue practice.", "accessory", "#3a6ea5", "w21-la-adverbs")

quests.append(quest(
    "w21-science-planets", "Planet Parade of Wonder", 21, 4, "science",
    "Science — Planets Overview (Design & Wonder)",
    "\"Each planet is unique — ordered paths declare the Creator's wisdom.\"",
    [dlg(SC, "Planets orbit the sun. Earth is the home God prepared with air, water, and life."),
     dlg(SC, "Learn order and features with wonder — Psalm 8 humility.")],
    [mc("w21s1", "Planets…",
        ["orbit the sun", "orbit only our kitchen", "are all identical moons", "vote in Congress"],
        "orbit the sun"),
     mc("w21s2", "Earth is special because…",
        ["it supports life with air and water", "it is the hottest star", "it has no moon", "it is flat and endless"],
        "it supports life with air and water"),
     tf("w21s3", "True or False: Studying planets can lead to praise of God."),
     mc("w21s4", "Mars is often called the…", ["red planet", "only ocean planet", "US capital", "yardstick"], "red planet"),
     mc("w21s5", "Jupiter is…", ["a giant planet", "Earth's moon", "a spelling adverb", "a Texas county only"], "a giant planet"),
     mc("w21s6", "Unique features of planets show…",
        ["variety in created order", "that chance is a god", "we should worship Saturn", "geometry is useless"],
        "variety in created order")],
    "planet_cards", 10))
add_item("planet_cards", "Planet Cards", "Simple cards naming planets and wonder facts.", "accessory", "#1d3557", "w21-science-planets")

quests.append(quest(
    "w21-history-symbols", "Symbols of the Nation", 21, 5, "history",
    "History — US Symbols & Respectful Patriotism",
    "\"Flag, eagle, mottos — symbols teach love of country with humility.\"",
    [dlg(CK, "US symbols include the flag, the bald eagle, and mottos that point to ideals."),
     dlg(CK, "Patriotism means love and respect for your country — not pride that mocks others.")],
    [mc("w21h1", "The US flag's stars stand for…", ["the states", "ounces", "planets only", "adverbs"], "the states"),
     mc("w21h2", "A national bird often named is the…",
        ["bald eagle", "briar boar", "shadow moth", "dust golem"], "bald eagle"),
     tf("w21h3", "True or False: Respecting the flag is part of good citizenship."),
     mc("w21h4", "Patriotism at this age means…",
        ["loving and respecting your country", "hating every other nation", "skipping history", "worshiping leaders"],
        "loving and respecting your country"),
     mc("w21h5", "Mottos on coins and seals often remind us of…",
        ["ideals like trust in God and unity", "only video games", "moon cheese", "fraction rules"],
        "ideals like trust in God and unity"),
     mc("w21h6", "Learning symbols helps us…",
        ["understand shared history", "measure gallons", "cast luck charms", "erase maps"],
        "understand shared history")],
    "eagle_pin", 10))
add_item("eagle_pin", "Eagle Pin", "A pin for US symbols and respectful patriotism.", "accessory", "#1d3557", "w21-history-symbols")

quests.append(quest(
    "w21-raid-review", "Raid Review: Geometry Gardens", 21, 5, "math",
    "Friday Raid — Week 21 Mixed Review",
    "\"Prove perimeter/angles, adverbs, planets, US symbols, Psalm 8.\"",
    [dlg(HS, "Week 21 proving. Mastery ≥80%."),
     dlg(HS, "Walk humbly under the heavens; fence the garden with true measure.")],
    [fb("w21r1", "Perimeter of square side 5?", "20"),
     fb("w21r2", "A right angle is ____ degrees", "90"),
     mc("w21r3", "Quickly is an…", ["adverb", "planet", "gallon", "republic"], "adverb"),
     mc("w21r4", "Planets orbit the…", ["sun", "bald eagle", "Alamo only", "dictionary"], "sun"),
     mc("w21r5", "US flag stars represent…",
        ["states", "ounces", "adverbs", "constellations to worship"], "states"),
     mc("w21r6", "Psalm 8 leads to…",
        ["humility and praise", "pride as creators of stars", "luck-charm reading", "skipping wonder"],
        "humility and praise"),
     tf("w21r7", "True or False: A hexagon has 6 sides."),
     fb("w21r8", "Triangle sides?", "3")],
    "garden_cloak", 30))
add_item("garden_cloak", "Garden Cloak", "Cloak earned at the Geometry Gardens raid review.", "cape", "#2d6a4f", "w21-raid-review")

# ========== WEEK 22 ==========
quests.append(quest(
    "w22-bible-cheerfulness", "Shine as Lights", 22, 1, "bible",
    "Bible — Philippians 2:14–15 & Cheerfulness",
    "\"Do all things without grumbling… shine as lights in the world.\"",
    [dlg(SB, "Philippians 2:14–15: no grumbling — shine as lights."),
     dlg(SB, "Virtue: Cheerfulness. A glad heart honors the High King.")],
    [mc("w22b1", "Philippians 2:14–15 tells us to avoid…",
        ["grumbling and arguing", "all cheerful songs", "map reading", "measuring area"],
        "grumbling and arguing"),
     mc("w22b2", "Shine as lights means…",
        ["live so others see goodness", "worship stars for luck", "hide truth", "complain loudly"],
        "live so others see goodness"),
     mc("w22b3", "Cheerfulness is…",
        ["glad, willing kindness", "forced fake smiles only", "mocking others", "skipping work"],
        "glad, willing kindness"),
     tf("w22b4", "True or False: Grumbling makes shining harder."),
     mc("w22b5", "Who wrote Philippians?", ["Paul", "a constellation", "Santa Anna", "Euclid only"], "Paul")],
    "cheer_lantern", 10))
add_item("cheer_lantern", "Cheer Lantern", "A small lantern for shining without grumbling.", "accessory", "#f4a261", "w22-bible-cheerfulness")

quests.append(quest(
    "w22-math-area", "Star Maps & Square Units", 22, 2, "math",
    "Math — Area vs Perimeter",
    "\"Area fills the inside; perimeter walks the edge — do not mix them.\"",
    [dlg(MB, "Area is square units inside a shape. For a rectangle: length × width."),
     dlg(MB, "Perimeter is around; area is inside. Label units carefully.")],
    [fb("w22m1", "Area of 4 by 3 rectangle?", "12"),
     fb("w22m2", "Area of 5 by 5 square?", "25"),
     fb("w22m3", "Perimeter of 4 by 3 rectangle?", "14"),
     mc("w22m4", "Area is measured in…", ["square units", "only gallons", "only degrees", "only verses"], "square units"),
     tf("w22m5", "True or False: Area and perimeter are the same thing.", "False"),
     fb("w22m6", "A 2 by 6 rectangle has area…", "12"),
     mc("w22m7", "Which asks for area?",
        ["How much carpet to cover the floor?", "How long is the fence around?", "How heavy is the bag?", "What year was 1845?"],
        "How much carpet to cover the floor?"),
     fb("w22m8", "1 × 8 rectangle area?", "8")],
    "area_grid", 12))
add_item("area_grid", "Area Grid", "A square-unit grid for area practice.", "belt", "#e9c46a", "w22-math-area")

quests.append(quest(
    "w22-la-maps-glossary", "Maps, Glossary, Index", 22, 3, "la",
    "LA — Reading Maps/Charts; Glossary & Index",
    "\"Find meaning in the glossary; find pages in the index; read the map key.\"",
    [dlg(MS, "A glossary defines key words. An index lists topics and page numbers."),
     dlg(MS, "Map keys (legends) explain symbols. Cheerful readers use tools!")],
    [mc("w22l1", "A glossary is…",
        ["a list of word meanings in a book", "a Texas river only", "a moon phase", "a raid enemy"],
        "a list of word meanings in a book"),
     mc("w22l2", "An index helps you…",
        ["find topics and page numbers", "weigh ounces", "orbit Mars", "cast a luck charm"],
        "find topics and page numbers"),
     mc("w22l3", "A map legend/key explains…",
        ["what symbols mean", "only adverbs", "only Colossians", "nothing useful"],
        "what symbols mean"),
     tf("w22l4", "True or False: Charts in texts can show data quickly."),
     mc("w22l5", "To find where Houston is discussed in a book, check the…",
        ["index", "moon", "sword", "cape color"], "index"),
     mc("w22l6", "Reading a map title tells you…",
        ["what the map is about", "your combat level", "a fraction sum only", "nothing"],
        "what the map is about")],
    "glossary_bookmark", 10))
add_item("glossary_bookmark", "Glossary Bookmark", "A bookmark for glossary, index, and map-key practice.", "accessory", "#3a6ea5", "w22-la-maps-glossary")

quests.append(quest(
    "w22-science-stars", "Stars for Seasons, Not Fate", 22, 4, "science",
    "Science — Stars & Constellations (Biblical Framing)",
    "\"Stars mark seasons as Genesis taught — we do not practice fortune-telling by stars.\"",
    [dlg(SC, "Constellations are star patterns people name to remember the sky. Genesis says lights are for signs and seasons."),
     dlg(SC, "We reject fortune-telling by stars — stars do not decide your destiny; God is Lord.")],
    [mc("w22s1", "Biblical framing: stars are for…",
        ["signs and seasons under God", "telling your personal fate like a god", "only video games", "tax rates"],
        "signs and seasons under God"),
     mc("w22s2", "Fortune-telling by stars is…",
        ["not a Christian practice we use", "required homework", "the same as astronomy", "Texas law"],
        "not a Christian practice we use"),
     mc("w22s3", "Astronomy means…",
        ["careful study of the heavens", "casting luck spells", "ignoring the sky", "graphing only"],
        "careful study of the heavens"),
     tf("w22s4", "True or False: Naming constellations can help navigate and learn seasons."),
     mc("w22s5", "We thank God for stars because…",
        ["He created them with purpose", "they vote", "they write essays", "they are random idols"],
        "He created them with purpose"),
     mc("w22s6", "Cheerful stewards…",
        ["study the sky without superstition", "fear luck charts as fate", "worship Orion", "skip Philippians"],
        "study the sky without superstition")],
    "star_season_chart", 10))
add_item("star_season_chart", "Star Season Chart", "A chart of seasons and star patterns — no fortune-telling.", "accessory", "#14213d", "w22-science-stars")

quests.append(quest(
    "w22-history-texas-geo", "Texas Regions & Symbols", 22, 5, "history",
    "History — Texas Geography & State Symbols",
    "\"Regions, rivers, cities; flag, flower, bird — know your state.\"",
    [dlg(CK, "Texas has varied regions (piney woods, gulf coast, plains, desert west) and major rivers and cities."),
     dlg(CK, "Symbols: Lone Star flag, bluebonnet (flower), mockingbird (bird) — learn with cheer.")],
    [mc("w22h1", "Texas state flower is often the…",
        ["bluebonnet", "cactus candy only", "rose of Mars", "oak leaf forever only"], "bluebonnet"),
     mc("w22h2", "Texas state bird is the…",
        ["mockingbird", "bald eagle only", "shadow moth", "penguin"], "mockingbird"),
     tf("w22h3", "True or False: Texas has more than one geographic region."),
     mc("w22h4", "A major Texas city is…", ["Houston", "Paris, France only", "the Moon", "Neptune"], "Houston"),
     mc("w22h5", "The Lone Star flag reminds us of…",
        ["Texas history and identity", "fate by stars", "a gallon", "random noise"],
        "Texas history and identity"),
     mc("w22h6", "Rivers on a Texas map help us…",
        ["locate regions and cities", "cast spells", "skip geography", "measure only ounces"],
        "locate regions and cities")],
    "bluebonnet_pin", 10))
add_item("bluebonnet_pin", "Bluebonnet Pin", "A pin for Texas symbols and geography.", "accessory", "#4c6ef5", "w22-history-texas-geo")

quests.append(quest(
    "w22-raid-review", "Raid Review: Star Maps & State Maps", 22, 5, "math",
    "Friday Raid — Week 22 Mixed Review",
    "\"Prove area, glossary/index, stars for seasons, Texas symbols, Philippians shine.\"",
    [dlg(HS, "Week 22 proving. Mastery ≥80%."),
     dlg(HS, "Shine cheerfully — maps and stars under the Lord's order.")],
    [fb("w22r1", "Area of 6×2 rectangle?", "12"),
     fb("w22r2", "Perimeter of 6×2 rectangle?", "16"),
     mc("w22r3", "Glossary gives…", ["word meanings", "combat loot", "luck charms", "only gallons"], "word meanings"),
     mc("w22r4", "We study stars for seasons, not…",
        ["fortune-telling about fate", "navigation help", "wonder at God", "science observation"],
        "fortune-telling about fate"),
     mc("w22r5", "Texas state flower?",
        ["bluebonnet", "tulip of Holland only", "sunflower of Kansas only", "pine cone"], "bluebonnet"),
     mc("w22r6", "Philippians 2: shine as…", ["lights", "grumblers", "idols", "shadows only"], "lights"),
     tf("w22r7", "True or False: Area uses square units."),
     mc("w22r8", "Index helps find…",
        ["topics and pages", "moon cheese", "enemy HP", "cape dyes only"], "topics and pages")],
    "starmap_cloak", 30))
add_item("starmap_cloak", "Star Map Cloak", "Cloak earned at the Star Maps & State Maps raid review.", "cape", "#14213d", "w22-raid-review")

# ========== WEEK 23 ==========
quests.append(quest(
    "w23-bible-micah", "Do Justly, Love Kindness", 23, 1, "bible",
    "Bible — Micah 6:8 & Doing Justly",
    "\"What does the Lord require? Do justice, love kindness, walk humbly.\"",
    [dlg(SB, "Micah 6:8: do justly, love kindness (mercy), walk humbly with God."),
     dlg(SB, "Virtue: doing justly and kindly — even when history is hard.")],
    [mc("w23b1", "Micah 6:8 requires…",
        ["justice, kindness, and humility with God", "cruelty and pride", "luck charms", "skipping mercy"],
        "justice, kindness, and humility with God"),
     mc("w23b2", "Doing justly means…",
        ["treating people fairly under God's ways", "cheating for gain", "ignoring the hurting", "boasting"],
        "treating people fairly under God's ways"),
     tf("w23b3", "True or False: Kindness belongs with justice."),
     mc("w23b4", "Walking humbly means…",
        ["remembering we need God", "thinking we are gods", "crushing others", "never learning"],
        "remembering we need God"),
     mc("w23b5", "Micah is…",
        ["a prophet in Scripture", "a planet", "a Texas bird only", "a polygon"],
        "a prophet in Scripture")],
    "micah_token", 10))
add_item("micah_token", "Micah Token", "A token for justice, kindness, and humility.", "accessory", "#9b2226", "w23-bible-micah")

quests.append(quest(
    "w23-math-multistep", "Multi-Step Mountain", 23, 2, "math",
    "Math — Multi-Step Word Problems",
    "\"Climb with one step at a time — choose +, −, ×, or ÷ wisely.\"",
    [dlg(MB, "Multi-step problems need a plan: what do you know? What do you need? Which operations?"),
     dlg(MB, "Show each step. Check if the answer makes sense.")],
    [fb("w23m1", "3 packs of 4 pencils, then lose 2: how many left?", "10"),
     fb("w23m2", "A baker makes 5 trays of 6 cookies and gives away 8. Left?", "22"),
     fb("w23m3", "12 apples shared equally by 3 kids, then each gets 1 more. Each has?", "5"),
     mc("w23m4", "First step for \"2 boxes of 8, then add 5\"?",
        ["multiply 2×8", "divide by 1845", "ignore the boxes", "only subtract forever"], "multiply 2×8"),
     tf("w23m5", "True or False: You may need more than one operation in one story."),
     fb("w23m6", "4 rows of 7 seats, 5 empty: filled seats?", "23"),
     mc("w23m7", "Choosing the operation means…",
        ["deciding + − × or ÷ from the story", "always adding only", "guessing without reading", "using luck charms"],
        "deciding + − × or ÷ from the story"),
     fb("w23m8", "10 stickers, buy 3 more packs of 5, total?", "25")],
    "multistep_slate", 12))
add_item("multistep_slate", "Multi-Step Slate", "A slate for planning multi-step word problems.", "belt", "#bc6c25", "w23-math-multistep")

quests.append(quest(
    "w23-la-narrative", "Conflict & Resolution Scroll", 23, 3, "la",
    "LA — Narrative Conflict/Resolution & Revise/Edit",
    "\"Stories need trouble and a fitting end — then revise and edit.\"",
    [dlg(MS, "Conflict is the problem. Resolution is how it works out. Use a revise/edit checklist."),
     dlg(MS, "Revise for clear ideas; edit for capitals, spelling, and punctuation.")],
    [mc("w23l1", "Conflict in a story is…",
        ["the problem the character faces", "only the title", "a math gallon", "a map legend"],
        "the problem the character faces"),
     mc("w23l2", "Resolution is…",
        ["how the problem is worked out", "the first word only", "a raid cloak", "a planet"],
        "how the problem is worked out"),
     mc("w23l3", "Revising mainly improves…",
        ["ideas and clarity", "only the font color", "enemy HP", "state flowers"],
        "ideas and clarity"),
     mc("w23l4", "Editing checks…",
        ["spelling, capitals, punctuation", "only combat", "only orbits", "nothing"],
        "spelling, capitals, punctuation"),
     tf("w23l5", "True or False: A checklist helps revise and edit."),
     mc("w23l6", "A strong narrative usually has…",
        ["beginning, problem, ending that fits", "only a glossary", "no characters", "random sentences"],
        "beginning, problem, ending that fits")],
    "revise_checklist", 10))
add_item("revise_checklist", "Revise Checklist", "A checklist for conflict, resolution, revise, and edit.", "accessory", "#3a6ea5", "w23-la-narrative")

quests.append(quest(
    "w23-science-weather-tools", "Weather Instruments Bench", 23, 4, "science",
    "Science — Weather Instruments",
    "\"Windsock, rain gauge, thermometer — measure what God's sky brings.\"",
    [dlg(SC, "A thermometer measures temperature. A rain gauge measures rainfall. A windsock shows wind direction."),
     dlg(SC, "You can make a simple windsock or rain gauge and record observations.")],
    [mc("w23s1", "A thermometer measures…", ["temperature", "area only", "justice", "spelling"], "temperature"),
     mc("w23s2", "A rain gauge measures…",
        ["how much rain falls", "planet count", "essay length", "flag stars"], "how much rain falls"),
     mc("w23s3", "A windsock helps show…",
        ["wind direction", "fraction sums", "Bible chapter only", "statehood year"], "wind direction"),
     tf("w23s4", "True or False: Recording weather is a stewardship skill."),
     mc("w23s5", "Weather instruments help us…",
        ["observe and measure honestly", "control the sun as a god", "skip science", "cast fate"],
        "observe and measure honestly"),
     mc("w23s6", "Which belongs on a weather bench?",
        ["rain gauge", "luck-charm scroll", "enemy sword", "only a cape"], "rain gauge")],
    "windsock_kit", 10))
add_item("windsock_kit", "Windsock Kit", "Simple kit ideas for windsock and rain gauge.", "accessory", "#4ea8de", "w23-science-weather-tools")

quests.append(quest(
    "w23-history-civil-war", "A Hard Chapter, Age-Right", 23, 5, "history",
    "History — 1860s National Conflict Overview (Careful, Factual)",
    "\"Union preserved; hardship endured; ending slavery was a step of justice — spoken gently.\"",
    [dlg(CK, "In the 1860s the United States faced a great national conflict. We speak carefully for third grade: the Union was preserved."),
     dlg(CK, "Many suffered. Ending slavery was a matter of justice — people are made in God's image. Avoid graphic detail; practice Micah 6:8.")],
    [mc("w23h1", "The 1860s conflict was within…",
        ["the United States", "the planet Jupiter", "only the Republic of Texas forever alone", "a spelling bee"],
        "the United States"),
     mc("w23h2", "One just outcome remembered is…",
        ["the end of slavery", "ending all maps", "banning kindness", "worshiping generals"],
        "the end of slavery"),
     tf("w23h3", "True or False: People are made in God's image, so injustice against people matters."),
     mc("w23h4", "Hardship in war times teaches us to…",
        ["value peace, courage, and mercy", "love cruelty", "ignore history", "celebrate harm"],
        "value peace, courage, and mercy"),
     mc("w23h5", "Preserving the Union means…",
        ["the nation stayed together as one country", "Texas left Earth", "math ended", "stars ruled fate"],
        "the nation stayed together as one country"),
     mc("w23h6", "We study this era with…",
        ["facts, respect, and age-right care", "graphic detail for fun", "party slogans as the only goal", "denial that slavery was wrong"],
        "facts, respect, and age-right care")],
    "union_ribbon", 10))
add_item("union_ribbon", "Union Ribbon", "A sober ribbon for union, hardship, and justice remembered carefully.", "accessory", "#1d3557", "w23-history-civil-war")

quests.append(quest(
    "w23-raid-review", "Raid Review: Multi-Step Mountain", 23, 5, "math",
    "Friday Raid — Week 23 Mixed Review",
    "\"Prove multi-step math, narrative parts, weather tools, 1860s overview, Micah 6:8.\"",
    [dlg(HS, "Week 23 proving. Mastery ≥80%."),
     dlg(HS, "Do justly, love kindness, walk humbly — one careful step at a time.")],
    [fb("w23r1", "2 bags of 9 apples, eat 3: left?", "15"),
     fb("w23r2", "5×4 then +6 =", "26"),
     mc("w23r3", "Story conflict is the…", ["problem", "map key only", "gallon", "constellation idol"], "problem"),
     mc("w23r4", "Rain gauge measures…", ["rainfall", "area of Texas only", "XP", "adverbs"], "rainfall"),
     mc("w23r5", "Ending slavery is remembered as…",
        ["a step of justice", "unimportant", "a moon phase", "a perimeter formula"], "a step of justice"),
     mc("w23r6", "Micah 6:8 includes…",
        ["do justice and love kindness", "grumble always", "worship stars", "skip humility"],
        "do justice and love kindness"),
     tf("w23r7", "True or False: Multi-step problems may use more than one operation."),
     mc("w23r8", "A windsock shows…",
        ["wind direction", "statehood year", "essay conclusions only", "enemy names"], "wind direction")],
    "mountain_cloak", 30))
add_item("mountain_cloak", "Mountain Cloak", "Cloak earned at the Multi-Step Mountain raid review.", "cape", "#bc6c25", "w23-raid-review")

# ========== WEEK 24 ==========
quests.append(quest(
    "w24-bible-order", "Decently and in Order", 24, 1, "bible",
    "Bible — 1 Corinthians 14:40 & Order",
    "\"All things should be done decently and in order.\"",
    [dlg(SB, "1 Corinthians 14:40: decently and in order — good for worship, work, and learning."),
     dlg(SB, "Virtue: Order. Fractions, spelling, and rebuilding all need orderly habits.")],
    [mc("w24b1", "1 Corinthians 14:40 calls for…",
        ["decent and orderly ways", "chaos as a virtue", "cruel disorder", "skipping care"],
        "decent and orderly ways"),
     mc("w24b2", "Order in learning looks like…",
        ["clear steps and careful practice", "never checking work", "mocking teachers", "random shouting"],
        "clear steps and careful practice"),
     tf("w24b3", "True or False: God values orderly, respectful practice."),
     mc("w24b4", "Decently means…",
        ["in a proper, respectful way", "rudely", "secretly evil", "only with magic"],
        "in a proper, respectful way"),
     mc("w24b5", "Who wrote 1 Corinthians?", ["Paul", "a bluebonnet", "Euclid only", "a windsock"], "Paul")],
    "order_band", 10))
add_item("order_band", "Order Band", "A band for doing things decently and in order.", "accessory", "#c9b037", "w24-bible-order")

quests.append(quest(
    "w24-math-fractions", "Fraction Forge", 24, 2, "math",
    "Math — Fractions of a Set; Compare; Add Like Denominators",
    "\"Parts of a set, compare fairly, add when denominators match.\"",
    [dlg(MB, "1/4 of 8 is 2. Same denominators compare by numerators. 1/5 + 2/5 = 3/5."),
     dlg(MB, "Forge carefully — order in every step.")],
    [fb("w24m1", "1/2 of 10 =", "5"),
     fb("w24m2", "1/4 of 8 =", "2"),
     fb("w24m3", "1/5 + 2/5 =", "3/5"),
     mc("w24m4", "Which is greater: 3/8 or 1/8?", ["3/8", "1/8", "they are planets", "neither exists"], "3/8"),
     fb("w24m5", "2/6 + 3/6 =", "5/6"),
     tf("w24m6", "True or False: To add fractions, denominators should match (like denominators)."),
     fb("w24m7", "1/3 of 9 =", "3"),
     mc("w24m8", "Compare 2/7 and 5/7: larger is…", ["5/7", "2/7", "both gallons", "neither"], "5/7")],
    "fraction_forge_tiles", 12))
add_item("fraction_forge_tiles", "Fraction Forge Tiles", "Tiles for parts of a set and like-denominator sums.", "belt", "#e76f51", "w24-math-fractions")

quests.append(quest(
    "w24-la-spelling", "Dictation & Spelling Mastery", 24, 3, "la",
    "LA — Spelling Review, Dictation, Vocabulary",
    "\"Hear it, write it, check it — mastery with orderly practice.\"",
    [dlg(MS, "Dictation trains listening and spelling together. Review patterns from earlier weeks."),
     dlg(MS, "Vocabulary tests check meaning — use words in sentences.")],
    [mc("w24l1", "Dictation practice means…",
        ["writing words/sentences you hear", "only drawing maps", "ignoring spelling", "combat typing"],
        "writing words/sentences you hear"),
     mc("w24l2", "A vocabulary test checks…",
        ["word meanings and use", "only HP", "only ounces", "luck charms"], "word meanings and use"),
     tf("w24l3", "True or False: Reviewing old spelling patterns builds mastery."),
     mc("w24l4", "Which shows careful spelling habits?",
        ["say the word, write, then check", "guess wildly forever", "never look back", "skip hard words always"],
        "say the word, write, then check"),
     mc("w24l5", "Plural of leaf is often…", ["leaves", "leafs always only", "leafes", "leaf"], "leaves"),
     mc("w24l6", "Orderly spelling study includes…",
        ["patterns, practice, and checking", "only luck", "only shouting", "no pencil"],
        "patterns, practice, and checking")],
    "dictation_slate", 10))
add_item("dictation_slate", "Dictation Slate", "A slate for spelling dictation and vocabulary checks.", "accessory", "#3a6ea5", "w24-la-spelling")

quests.append(quest(
    "w24-science-plants", "Plant Parts Workshop", 24, 4, "science",
    "Science — Roots, Stems, Leaves, Flowers",
    "\"Roots, stems, leaves, flowers — each part serves the plant's design.\"",
    [dlg(SC, "Roots take in water; stems support and carry; leaves help make food with light; flowers aid reproduction."),
     dlg(SC, "If available, observe a flower's parts carefully and orderly.")],
    [mc("w24s1", "Roots mainly…",
        ["take in water and anchor the plant", "vote", "write essays", "measure area"],
        "take in water and anchor the plant"),
     mc("w24s2", "Leaves help plants…",
        ["use light to make food", "cast luck charms", "forge iron", "run for office"],
        "use light to make food"),
     mc("w24s3", "Stems…",
        ["support and carry water/nutrients", "are always roots", "are moons", "are flags"],
        "support and carry water/nutrients"),
     tf("w24s4", "True or False: Flowers can help plants make seeds."),
     mc("w24s5", "Observing plant parts teaches…",
        ["designed order in living things", "that plants are random accidents with no parts", "only Texas politics", "fractions alone"],
        "designed order in living things"),
     mc("w24s6", "Which is a plant part?", ["leaf", "windsock only", "badge only", "raid cloak"], "leaf")],
    "plant_part_cards", 10))
add_item("plant_part_cards", "Plant Part Cards", "Cards for roots, stems, leaves, and flowers.", "accessory", "#2d6a4f", "w24-science-plants")

quests.append(quest(
    "w24-history-rebuilders", "Rebuilders & Inventors", 24, 5, "history",
    "History — Reuniting & Inventors/Builders Overview",
    "\"After hard war years, people rebuilt; inventors and builders showed curiosity and work.\"",
    [dlg(CK, "After the hard 1860s, the nation faced reuniting and rebuilding — hard, hopeful work."),
     dlg(CK, "Inventors and builders (age-right examples parents may choose) show curiosity, diligence, and service.")],
    [mc("w24h1", "After the hard 1860s conflict, the nation needed to…",
        ["reunite and rebuild", "erase all maps", "end all inventing", "ban kindness"],
        "reunite and rebuild"),
     mc("w24h2", "Inventors often show…",
        ["curiosity and careful work", "laziness only", "luck-charm mastery", "hatred of order"],
        "curiosity and careful work"),
     tf("w24h3", "True or False: Builders help communities with useful skills."),
     mc("w24h4", "Reuniting a nation requires…",
        ["patience, justice, and hard work", "more injustice", "ignoring God's image in people", "chaos forever"],
        "patience, justice, and hard work"),
     mc("w24h5", "Learning inventors' stories encourages…",
        ["trying ideas and serving others", "quitting when hard", "mocking builders", "skipping math"],
        "trying ideas and serving others"),
     mc("w24h6", "Orderly rebuilding fits the virtue of…",
        ["order", "cruelty", "grumbling", "idolatry"], "order")],
    "inventor_compass", 10))
add_item("inventor_compass", "Inventor Compass", "A compass token for curiosity, rebuilding, and useful work.", "accessory", "#9b2226", "w24-history-rebuilders")

quests.append(quest(
    "w24-raid-review", "Raid Review: Fraction Forge", 24, 5, "math",
    "Friday Raid — Week 24 Mixed Review",
    "\"Prove fractions, spelling/dictation, plant parts, rebuilders, 1 Cor 14:40.\"",
    [dlg(HS, "Week 24 proving. Mastery ≥80%."),
     dlg(HS, "Decently and in order — forge fractions and rebuild habits.")],
    [fb("w24r1", "1/2 of 8 =", "4"),
     fb("w24r2", "1/8 + 3/8 =", "4/8"),
     mc("w24r3", "Dictation trains…",
        ["listening and spelling", "only combat", "luck charms", "rain only"], "listening and spelling"),
     mc("w24r4", "Roots mainly…", ["take in water", "write laws", "orbit Mars", "wave flags"], "take in water"),
     mc("w24r5", "After war, nations often must…",
        ["reunite and rebuild", "ban all work", "worship inventors", "end maps"], "reunite and rebuild"),
     mc("w24r6", "1 Corinthians 14:40: do things…",
        ["decently and in order", "chaotically", "cruelly", "secretly evil"], "decently and in order"),
     tf("w24r7", "True or False: 2/5 + 1/5 = 3/5."),
     mc("w24r8", "Which is larger: 4/9 or 1/9?", ["4/9", "1/9", "neither", "both are yards"], "4/9")],
    "forge_cloak", 30))
add_item("forge_cloak", "Forge Cloak", "Cloak earned at the Fraction Forge raid review.", "cape", "#e76f51", "w24-raid-review")

# ========== WEEK 25 ==========
quests.append(quest(
    "w25-bible-honor", "Honor All People", 25, 1, "bible",
    "Bible — 1 Peter 2:17 & Honor",
    "\"Honor everyone. Love the brotherhood. Fear God. Honor the emperor.\"",
    [dlg(SB, "1 Peter 2:17: honor people, love the church family, fear God, respect rightful rulers."),
     dlg(SB, "Virtue: Honor — citizenship begins with respect.")],
    [mc("w25b1", "1 Peter 2:17 teaches us to…",
        ["honor people and fear God", "mock everyone", "hate rulers always", "ignore God"],
        "honor people and fear God"),
     mc("w25b2", "Honor means…",
        ["showing respect and worth", "cruel teasing", "cheating", "grumbling only"],
        "showing respect and worth"),
     tf("w25b3", "True or False: Fearing God comes with honoring others rightly."),
     mc("w25b4", "Citizenship learning includes…",
        ["respect for people and lawful order", "breaking laws for fun", "idolizing politicians", "skipping kindness"],
        "respect for people and lawful order"),
     mc("w25b5", "Who wrote 1 Peter?", ["Peter", "a bar graph", "a bluebonnet", "a gallon jug"], "Peter")],
    "honor_medallion", 10))
add_item("honor_medallion", "Honor Medallion", "A medallion for honoring people and fearing God.", "accessory", "#c9a227", "w25-bible-honor")

quests.append(quest(
    "w25-math-graphs", "Citizen Graphs", 25, 2, "math",
    "Math — Bar Graphs & Pictographs",
    "\"Read and make simple graphs — data tells a clear story.\"",
    [dlg(MB, "Pictographs use pictures; bar graphs use bars. Read the title, labels, and key."),
     dlg(MB, "Make a graph from counts you gather — orderly and honest.")],
    [mc("w25m1", "A bar graph uses…",
        ["bars to show amounts", "only poetry", "luck charms", "swords"], "bars to show amounts"),
     mc("w25m2", "A pictograph uses…",
        ["pictures or symbols for amounts", "only blank paper", "enemy HP", "moon worship"],
        "pictures or symbols for amounts"),
     fb("w25m3", "If one star = 2 votes and you see 3 stars, total votes?", "6"),
     tf("w25m4", "True or False: Graph titles help you know what data means."),
     mc("w25m5", "To compare two categories on a bar graph, look at…",
        ["bar heights/lengths", "cape color only", "luck charms", "raid loot"], "bar heights/lengths"),
     fb("w25m6", "If a bar reaches 8 on the scale, the value is…", "8"),
     mc("w25m7", "A key on a pictograph tells…",
        ["what each picture stands for", "your combat level", "a Bible verse only", "nothing"],
        "what each picture stands for"),
     fb("w25m8", "2 stars = 10 if one star = ?", "5")],
    "graph_tablet", 12))
add_item("graph_tablet", "Graph Tablet", "A tablet for bar graphs and pictographs.", "belt", "#264653", "w25-math-graphs")

quests.append(quest(
    "w25-la-opinion-oral", "Opinion & Oral Square", 25, 3, "la",
    "LA — Opinion Writing with Reasons & Oral Practice",
    "\"State an opinion, give reasons, speak clearly with honor.\"",
    [dlg(MS, "Opinion writing: claim + reasons + closing. Oral share: stand tall, speak clearly, look kindly."),
     dlg(MS, "Disagree with honor — no mocking.")],
    [mc("w25l1", "An opinion statement tells…",
        ["what you think or prefer", "only a measured fact with a tool", "a random number", "an enemy name"],
        "what you think or prefer"),
     mc("w25l2", "Strong opinion writing needs…",
        ["reasons that support the claim", "no reasons", "only insults", "only graphs with no words"],
        "reasons that support the claim"),
     mc("w25l3", "Oral presentation practice includes…",
        ["clear voice and respectful posture", "mumbling at the floor forever", "shouting insults", "reading silently only never aloud"],
        "clear voice and respectful posture"),
     tf("w25l4", "True or False: You can disagree respectfully."),
     mc("w25l5", "A closing sentence may…",
        ["restate the opinion briefly", "start a new unrelated topic only", "erase reasons", "list ounces"],
        "restate the opinion briefly"),
     mc("w25l6", "Honor in speech means…",
        ["kind, truthful words", "cruel teasing", "lying to win", "ignoring listeners"],
        "kind, truthful words")],
    "opinion_scroll_case", 10))
add_item("opinion_scroll_case", "Opinion Scroll Case", "A case for opinion drafts and oral-share notes.", "accessory", "#3a6ea5", "w25-la-opinion-oral")

quests.append(quest(
    "w25-science-stewardship", "Stewards of Creation Care", 25, 4, "science",
    "Science — Conservation as Stewardship",
    "\"Care for land, water, and creatures — stewardship, not political slogans.\"",
    [dlg(SC, "Conservation here means stewardship: care for what God made — clean habits, no wasteful harm."),
     dlg(SC, "We avoid turning creation care into party politics; we practice thankful responsibility.")],
    [mc("w25s1", "Stewardship of creation means…",
        ["caring wisely for what God made", "worshiping Earth as a goddess", "littering freely", "ignoring living things"],
        "caring wisely for what God made"),
     mc("w25s2", "A simple stewardship act is…",
        ["not littering and using resources carefully", "polluting for fun", "hating farms", "skipping nature walks"],
        "not littering and using resources carefully"),
     tf("w25s3", "True or False: This quest frames care as stewardship, not political campaigning."),
     mc("w25s4", "Thankful stewards…",
        ["respect land, water, and creatures", "waste on purpose", "mock farmers", "deny God's ownership"],
        "respect land, water, and creatures"),
     mc("w25s5", "Creation belongs ultimately to…",
        ["God the Creator", "random chance as lord", "only one political party", "luck-charm writers"],
        "God the Creator"),
     mc("w25s6", "Kids can steward by…",
        ["cleaning up and treating nature kindly", "breaking trees for sport", "dumping trash in rivers", "fearing outdoor air always"],
        "cleaning up and treating nature kindly")],
    "steward_seed_pouch", 10))
add_item("steward_seed_pouch", "Steward Seed Pouch", "A pouch for planting and creation-care habits.", "accessory", "#2d6a4f", "w25-science-stewardship")

quests.append(quest(
    "w25-history-citizenship", "Citizens in Training", 25, 5, "history",
    "History — Community Helpers, Citizenship & Voting Idea",
    "\"Helpers serve; adults vote; children learn respect for law and neighbors.\"",
    [dlg(CK, "Community helpers (teachers, firefighters, nurses, and more) serve the common good."),
     dlg(CK, "In the US, adults vote for leaders. Children learn why laws and peaceful respect matter — honor all people.")],
    [mc("w25h1", "Voting in the US is mainly a responsibility of…",
        ["adult citizens", "planets", "third-grade raid bosses", "constellations"], "adult citizens"),
     mc("w25h2", "Community helpers…",
        ["serve neighbors in important roles", "exist only in myths", "replace parents entirely", "ban learning"],
        "serve neighbors in important roles"),
     tf("w25h3", "True or False: Children can practice citizenship by respecting laws and people."),
     mc("w25h4", "Learning about voting helps kids…",
        ["understand peaceful self-government", "cast ballots illegally as kids", "hate all leaders", "skip honor"],
        "understand peaceful self-government"),
     mc("w25h5", "Respect for law fits the virtue of…",
        ["honor", "chaos", "cruelty", "idolatry of self"], "honor"),
     mc("w25h6", "A good citizen habit is…",
        ["telling the truth and helping neighbors", "vandalizing", "lying for fun", "mocking helpers"],
        "telling the truth and helping neighbors")],
    "citizen_pin", 10))
add_item("citizen_pin", "Citizen Pin", "A pin for community helpers and citizenship learning.", "accessory", "#9b2226", "w25-history-citizenship")

quests.append(quest(
    "w25-raid-review", "Raid Review: Citizen Scribes", 25, 5, "math",
    "Friday Raid — Week 25 Mixed Review",
    "\"Prove graphs, opinion/oral, stewardship, citizenship, 1 Peter 2:17.\"",
    [dlg(HS, "Week 25 proving. Mastery ≥80%."),
     dlg(HS, "Honor everyone; steward creation; speak opinions with reasons.")],
    [fb("w25r1", "If one star=2 and you see 4 stars, total?", "8"),
     mc("w25r2", "Bar graphs show amounts with…", ["bars", "only swords", "only moons", "luck charms"], "bars"),
     mc("w25r3", "Opinion writing needs…", ["reasons", "only insults", "no claim", "silent forever"], "reasons"),
     mc("w25r4", "Stewardship means…",
        ["caring for God's creation", "Earth worship as goddess", "littering", "party slogans as the whole point"],
        "caring for God's creation"),
     mc("w25r5", "Adults vote; children learn…",
        ["respect for law and people", "to break laws", "to hate helpers", "luck charms"],
        "respect for law and people"),
     mc("w25r6", "1 Peter 2:17: honor…",
        ["everyone (with fear of God)", "no one", "only yourself", "created lights as gods"],
        "everyone (with fear of God)"),
     tf("w25r7", "True or False: Pictographs use pictures for data."),
     mc("w25r8", "Oral share should be…",
        ["clear and respectful", "cruel", "secret mumbling only", "false on purpose"],
        "clear and respectful")],
    "citizen_cloak", 30))
add_item("citizen_cloak", "Citizen Cloak", "Cloak earned at the Citizen Scribes raid review.", "cape", "#264653", "w25-raid-review")

# ========== WEEK 26 ==========
quests.append(quest(
    "w26-bible-perseverance", "Run with Perseverance", 26, 1, "bible",
    "Bible — Hebrews 12:1 & Perseverance",
    "\"Let us run with perseverance the race set before us.\"",
    [dlg(SB, "Hebrews 12:1: lay aside weights and sin; run with perseverance."),
     dlg(SB, "Virtue: Perseverance — keep going in learning and character.")],
    [mc("w26b1", "Hebrews 12:1 calls us to run with…",
        ["perseverance", "grumbling only", "quitting", "pride as our god"], "perseverance"),
     mc("w26b2", "Perseverance means…",
        ["keeping on through difficulty", "giving up at once", "cheating to finish", "mocking the slow"],
        "keeping on through difficulty"),
     tf("w26b3", "True or False: The race image means a faithful life, not only a foot race."),
     mc("w26b4", "Laying aside hindrances looks like…",
        ["putting away habits that slow obedience", "collecting more sin", "ignoring God", "hating practice"],
        "putting away habits that slow obedience"),
     mc("w26b5", "Who is the focus we look to in the race (Hebrews context)?",
        ["Jesus", "a bar graph", "a bluebonnet only", "Sam Houston alone"], "Jesus")],
    "perseverance_band", 10))
add_item("perseverance_band", "Perseverance Band", "A band for running the race with endurance.", "accessory", "#7f5539", "w26-bible-perseverance")

quests.append(quest(
    "w26-math-mixed", "Trail Mixed Review", 26, 2, "math",
    "Math — Geometry, Measurement, Graphs Mixed",
    "\"Review the trail: measure, shape, area, perimeter, graphs.\"",
    [dlg(MB, "Mixed drill week: length, weight/capacity spot checks, perimeter/area, and graph reading."),
     dlg(MB, "Persevere — accuracy over hurry.")],
    [fb("w26m1", "3 feet = ____ yards", "1"),
     fb("w26m2", "Area of 7×3?", "21"),
     fb("w26m3", "Perimeter of 7×3 rectangle?", "20"),
     fb("w26m4", "16 oz = ____ lb", "1"),
     fb("w26m5", "If one star=5 and you see 2 stars, total?", "10"),
     fb("w26m6", "A right angle is ____ degrees", "90"),
     tf("w26m7", "True or False: Perimeter is the distance around."),
     fb("w26m8", "4 quarts = ____ gallon", "1")],
    "trail_abacus", 12))
add_item("trail_abacus", "Trail Abacus", "An abacus for mixed measurement and geometry review.", "belt", "#7f5539", "w26-math-mixed")

quests.append(quest(
    "w26-la-book-project", "Book Project Trail", 26, 3, "la",
    "LA — Book Project & Character Traits / Virtues",
    "\"Choose a favorite chapter book; name traits that mirror virtues.\"",
    [dlg(MS, "Book project: title, main character, problem, what you learned."),
     dlg(MS, "Tie a character trait to a virtue — courage, kindness, perseverance, honor.")],
    [mc("w26l1", "A book project summary should include…",
        ["title and important story points", "only the ISBN forever", "enemy loot tables", "no title"],
        "title and important story points"),
     mc("w26l2", "Character traits are…",
        ["qualities that describe a person in the story", "only page numbers", "only graphs", "moon phases"],
        "qualities that describe a person in the story"),
     tf("w26l3", "True or False: Virtues like perseverance can appear in fiction characters."),
     mc("w26l4", "Connecting traits to virtues helps you…",
        ["grow in wisdom while reading", "skip the book", "hate reading", "worship characters"],
        "grow in wisdom while reading"),
     mc("w26l5", "A main character is…",
        ["a central person in the story", "always the villain only", "the glossary", "a rain gauge"],
        "a central person in the story"),
     mc("w26l6", "Sharing a book project orally should be…",
        ["clear and respectful", "rude", "secret forever", "false on purpose"],
        "clear and respectful")],
    "book_project_folio", 10))
add_item("book_project_folio", "Book Project Folio", "A folio for chapter-book projects and virtue ties.", "accessory", "#3a6ea5", "w26-la-book-project")

quests.append(quest(
    "w26-science-texas-habitats", "Texas Habitat Trail", 26, 4, "science",
    "Science — Texas Habitats Overview",
    "\"Prairie, piney woods, gulf, desert — homes designed for their creatures.\"",
    [dlg(SC, "Texas habitats differ: prairies, piney woods, gulf coast, western desert, and more."),
     dlg(SC, "Creatures fit their homes — evidence of provision, not accident-as-god.")],
    [mc("w26s1", "A habitat is…",
        ["a living place that meets needs", "a fraction tile", "a political slogan", "a cape dye"],
        "a living place that meets needs"),
     mc("w26s2", "Piney woods are known for…",
        ["many trees / forest character", "only ocean water forever", "being the moon", "having no living things"],
        "many trees / forest character"),
     mc("w26s3", "Gulf Coast habitats are near…", ["the sea", "only the North Pole", "Jupiter", "a dictionary"], "the sea"),
     tf("w26s4", "True or False: Deserts can still hold specially suited plants and animals."),
     mc("w26s5", "Prairies are often…",
        ["grassy open lands", "deep ocean trenches only", "star cores", "libraries only"],
        "grassy open lands"),
     mc("w26s6", "Studying Texas habitats teaches…",
        ["variety in created homes for creatures", "that Texas has no nature", "luck charms", "only graphs"],
        "variety in created homes for creatures")],
    "habitat_map_texas", 10))
add_item("habitat_map_texas", "Texas Habitat Map", "A simple map of major Texas habitat regions.", "accessory", "#2d6a4f", "w26-science-texas-habitats")

quests.append(quest(
    "w26-history-famous", "Famous Names, Good Character", 26, 5, "history",
    "History — Famous Texans / Americans of Good Character",
    "\"Parent-chosen examples of courage, service, and perseverance.\"",
    [dlg(CK, "Learn a few famous Texans or Americans your family chooses for good character — not celebrity alone."),
     dlg(CK, "Ask: How did they serve? Where did they persevere? What virtue shines?")],
    [mc("w26h1", "We study famous people best by asking about…",
        ["character and service", "only fame and money", "luck charms", "enemy damage"],
        "character and service"),
     mc("w26h2", "Perseverance in a biography often shows…",
        ["not quitting when work is hard", "never trying", "cruelty", "lying"],
        "not quitting when work is hard"),
     tf("w26h3", "True or False: Parents may choose age-right examples of good character."),
     mc("w26h4", "A good reason to remember a leader is…",
        ["courage and service to others", "how loudly they insulted people", "magic powers", "cape fashion alone"],
        "courage and service to others"),
     mc("w26h5", "Texas and American stories together help us…",
        ["see shared virtues across history", "erase Texas", "ban reading", "worship celebrities"],
        "see shared virtues across history"),
     mc("w26h6", "Character over celebrity means…",
        ["virtue matters more than fame", "fame is the only good", "skip all history", "mock helpers"],
        "virtue matters more than fame")],
    "character_ribbon", 10))
add_item("character_ribbon", "Character Ribbon", "A ribbon for biographies of good character.", "accessory", "#9b2226", "w26-history-famous")

quests.append(quest(
    "w26-raid-review", "Raid Review: Trail of Stories", 26, 5, "math",
    "Friday Raid — Week 26 Mixed Review",
    "\"Prove mixed math, book project ideas, Texas habitats, character stories, Hebrews 12:1.\"",
    [dlg(HS, "Week 26 proving. Mastery ≥80%."),
     dlg(HS, "Persevere on the trail — stories, habitats, and steady measure.")],
    [fb("w26r1", "Area of 5×4?", "20"),
     fb("w26r2", "12 inches = ____ foot", "1"),
     mc("w26r3", "Book projects may tie traits to…",
        ["virtues", "only loot", "luck charms", "random noise"], "virtues"),
     mc("w26r4", "A Texas habitat example is…",
        ["prairie or piney woods", "the core of the sun", "a fraction denominator only", "a PIN code"],
        "prairie or piney woods"),
     mc("w26r5", "Famous people are best judged by…",
        ["character and service", "fame alone", "cruelty", "luck-charm pages"],
        "character and service"),
     mc("w26r6", "Hebrews 12:1: run with…",
        ["perseverance", "grumbling", "quitting", "pride as lord"], "perseverance"),
     tf("w26r7", "True or False: Bar graphs help compare amounts."),
     fb("w26r8", "Perimeter of a square side 6?", "24")],
    "trail_cloak", 30))
add_item("trail_cloak", "Trail Cloak", "Cloak earned at the Trail of Stories raid review.", "cape", "#7f5539", "w26-raid-review")

# ========== WEEK 27 ==========
quests.append(quest(
    "w27-bible-stewardship", "Stewardship Feast Memory", 27, 1, "bible",
    "Bible — Campaign III Memory & Stewardship",
    "\"Remember the verses; practice stewardship of gifts and creation.\"",
    [dlg(SB, "Campaign III memory feast: Genesis lights, Colossians work, Psalm 8 humility, Philippians shine, Micah justice, order, honor, perseverance."),
     dlg(SB, "Virtue crown for this feast: Stewardship — all we have is the High King's trust.")],
    [mc("w27b1", "Stewardship means…",
        ["faithfully caring for what God entrusts", "owning creation as gods", "wasting freely", "ignoring gifts"],
        "faithfully caring for what God entrusts"),
     mc("w27b2", "Micah 6:8 includes justice and…",
        ["kindness (mercy) and humility", "cruelty", "luck charms", "grumbling"],
        "kindness (mercy) and humility"),
     mc("w27b3", "Psalm 8 leads to…",
        ["humility before the Creator", "star worship", "pride", "chaos"],
        "humility before the Creator"),
     tf("w27b4", "True or False: Working heartily (Colossians 3:23) is part of stewardship."),
     mc("w27b5", "Philippians 2: shine as lights without…",
        ["grumbling", "cheer", "honor", "perseverance"], "grumbling"),
     mc("w27b6", "Campaign III virtues include…",
        ["perseverance, stewardship, patriotism (respectful)", "cruelty and greed", "idolatry of nation as god", "laziness"],
        "perseverance, stewardship, patriotism (respectful)")],
    "stewardship_cup", 12))
add_item("stewardship_cup", "Stewardship Cup", "A feast cup for Campaign III stewardship memory.", "accessory", "#c9b037", "w27-bible-stewardship")

quests.append(quest(
    "w27-math-cumulative", "Builders Fluency Check", 27, 2, "math",
    "Math — Measurement, Geometry, Fractions, Multi-Step, Graphs",
    "\"Prove the Builders of the Republic math trail.\"",
    [dlg(MB, "Cumulative check: length/weight/capacity, perimeter/area, fractions, multi-step, graphs."),
     dlg(MB, "Builders measure twice and think once more.")],
    [fb("w27m1", "36 inches = ____ yards", "1"),
     fb("w27m2", "2 feet = ____ inches", "24"),
     fb("w27m3", "Area of 8×4?", "32"),
     fb("w27m4", "Perimeter of 8×4 rectangle?", "24"),
     fb("w27m5", "1/4 of 12 =", "3"),
     fb("w27m6", "2/7 + 3/7 =", "5/7"),
     fb("w27m7", "3 packs of 5, then −4 =", "11"),
     fb("w27m8", "If one star=3 and 4 stars show, total?", "12"),
     fb("w27m9", "16 oz = ____ lb", "1"),
     tf("w27m10", "True or False: Area and perimeter measure different things.")],
    "builders_stone", 15))
add_item("builders_stone", "Builders Stone", "A stone for Campaign III math fluency.", "accessory", "#d4a017", "w27-math-cumulative")

quests.append(quest(
    "w27-la-portfolio", "Scribe Three-Paragraph Feast", 27, 3, "la",
    "LA — 3-Paragraph Piece, Oral Share, Mechanics",
    "\"Write three paragraphs; share aloud; check mechanics.\"",
    [dlg(MS, "Feast portfolio: informational or opinion three-paragraph piece, oral share, capitals/spelling/punctuation check."),
     dlg(MS, "Linking words and clear reasons still matter.")],
    [mc("w27l1", "Three paragraphs often mean…",
        ["intro, body, conclusion", "only one word", "only a title", "combat log"],
        "intro, body, conclusion"),
     mc("w27l2", "Oral share should be…",
        ["clear and respectful", "rude", "silent forever", "false"], "clear and respectful"),
     mc("w27l3", "Mechanics check includes…",
        ["capitals, spelling, punctuation", "only cape color", "only HP", "luck charms"],
        "capitals, spelling, punctuation"),
     tf("w27l4", "True or False: Linking words help readers follow."),
     mc("w27l5", "A glossary helps with…",
        ["word meanings", "wind only", "enemy spawns", "ounces alone"], "word meanings"),
     mc("w27l6", "Dialogue uses…",
        ["quotation marks", "no marks ever", "only numbers", "only graphs"], "quotation marks"),
     mc("w27l7", "Adverbs often tell…",
        ["how, when, or where", "only statehood years", "only habitat names", "nothing"],
        "how, when, or where")],
    "campaign_iii_portfolio", 12))
add_item("campaign_iii_portfolio", "Campaign III Portfolio", "A portfolio folder for the three-paragraph feast piece.", "accessory", "#3a6ea5", "w27-la-portfolio")

quests.append(quest(
    "w27-science-poster", "Space & Stewardship Poster", 27, 4, "science",
    "Science — Space & Stewardship Poster; Moon Chart",
    "\"Poster the heavens with gratitude; finish the moon chart.\"",
    [dlg(SC, "Make a poster: solar system as created order + stewardship care — no fortune-telling by stars."),
     dlg(SC, "Complete your moon phase observations and share one wonder.")],
    [mc("w27s1", "Solar system study should honor…",
        ["the Creator's order", "sun worship", "fate-telling stars", "chaos as lord"],
        "the Creator's order"),
     mc("w27s2", "Moon charts track…",
        ["changing shapes over nights", "tax rates", "only spelling", "raid XP"],
        "changing shapes over nights"),
     mc("w27s3", "Stewardship on a poster might show…",
        ["care for land and creatures", "littering tips", "Earth goddess worship", "party slogans as the whole lesson"],
        "care for land and creatures"),
     tf("w27s4", "True or False: Astronomy is careful study; fortune-telling by stars is rejected here."),
     mc("w27s5", "Plant parts include…",
        ["roots, stems, leaves, flowers", "only capes", "only PINs", "only bars on graphs"],
        "roots, stems, leaves, flowers"),
     mc("w27s6", "Weather tools include…",
        ["thermometer and rain gauge", "luck charm only", "only swords", "only cloaks"],
        "thermometer and rain gauge"),
     mc("w27s7", "Texas habitats show…",
        ["varied homes for creatures", "no living things", "only one biome worldwide", "nothing to learn"],
        "varied homes for creatures")],
    "space_steward_poster", 12))
add_item("space_steward_poster", "Space Steward Poster Kit", "Kit token for space-order and stewardship posters.", "accessory", "#2d6a4f", "w27-science-poster")

quests.append(quest(
    "w27-history-review", "Republic to Statehood Review", 27, 5, "history",
    "History — Texas Republic→Statehood→Geography; US Growth",
    "\"Oral quiz: Republic, 1845, symbols, geography, careful US growth notes.\"",
    [dlg(CK, "Review: Republic of Texas, statehood 1845, regions/symbols, US symbols, careful 1860s notes, rebuilders."),
     dlg(CK, "Speak facts with honor and age-right care.")],
    [mc("w27h1", "Texas statehood year?", ["1845", "1776", "1492", "1914"], "1845"),
     mc("w27h2", "Before statehood Texas was a…", ["republic", "planet", "constellation", "gallon"], "republic"),
     mc("w27h3", "Texas state flower?",
        ["bluebonnet", "rose of England only", "cactus candy only", "pine of Maine only"], "bluebonnet"),
     mc("w27h4", "US flag stars stand for…", ["states", "ounces", "adverbs", "moons"], "states"),
     tf("w27h5", "True or False: Ending slavery is remembered as a justice theme."),
     mc("w27h6", "Sam Houston is tied to…",
        ["Republic of Texas leadership", "inventing fractions", "writing Micah", "building rain gauges only"],
        "Republic of Texas leadership"),
     mc("w27h7", "Respectful patriotism means…",
        ["love of country with humility", "hating all other nations", "worshiping the flag as God", "skipping history"],
        "love of country with humility")],
    "republic_timeline_ribbon", 12))
add_item("republic_timeline_ribbon", "Republic Timeline Ribbon", "A ribbon for Republic→statehood→growth review.", "accessory", "#9b2226", "w27-history-review")

quests.append(quest(
    "w27-raid-feast", "Campaign III Raid Review & Feast", 27, 5, "math",
    "Friday Raid — Campaign III Cumulative Feast",
    "\"Prove the Builders of the Republic — then receive the Campaign III badge.\"",
    [dlg(HS, "Campaign III complete when you master this feast review (≥80%). Well done, builder!"),
     dlg(HS, "Parents: Campaign III badge notes. Campaign IV — Light for the Realm — continues the trail.")],
    [fb("w27r1", "3 feet = ____ yard(s)", "1"),
     fb("w27r2", "Area of 6×5?", "30"),
     fb("w27r3", "1/3 of 9 =", "3"),
     fb("w27r4", "1/6 + 4/6 =", "5/6"),
     fb("w27r5", "2×8 then +5 =", "21"),
     fb("w27r6", "If one star=4 and 3 stars, total?", "12"),
     mc("w27r7", "Texas became a state in…", ["1845", "1836 only forever", "1620", "2000"], "1845"),
     mc("w27r8", "Stars are for seasons under God — not…",
        ["fortune-telling about fate", "navigation help", "wonder", "science observation"],
        "fortune-telling about fate"),
     mc("w27r9", "Stewardship means…",
        ["caring for what God entrusted", "wasting creation", "Earth goddess worship", "ignoring neighbors"],
        "caring for what God entrusted"),
     tf("w27r10", "True or False: Campaign III strengthens measurement, geometry, research writing, solar order, and Texas Republic→statehood.")],
    "campaign_iii_badge", 40, ["builders_cloak"]))
add_item("campaign_iii_badge", "Campaign III Badge", "The Builders of the Republic campaign badge — measurement, geometry, and stewardship.", "accessory", "#c9a227", "w27-raid-feast")
add_item("builders_cloak", "Builders Cloak", "A feast cloak awarded with the Campaign III badge.", "cape", "#8b6914", "w27-raid-feast")


def week_num(qid: str) -> int:
    if not qid.startswith("w"):
        return 0
    num = ""
    for ch in qid[1:]:
        if ch.isdigit():
            num += ch
        else:
            break
    return int(num) if num else 0

def main():
    assert len(quests) == 54, f"expected 54 quests, got {len(quests)}"
    assert len(items) == 55, f"expected 55 items, got {len(items)}"

    for q in quests:
        for ch in q["challenges"]:
            assert ch.get("answer") not in (None, ""), (q["id"], ch["id"])
            if ch["type"] in ("multiple-choice", "true-false"):
                assert ch["answer"] in ch["options"], (q["id"], ch["id"], ch["answer"])

    qpath = ROOT / "quests.json"
    ipath = ROOT / "items.json"
    wpath = ROOT / "world.json"

    old_q = json.loads(qpath.read_text())
    old_q = [q for q in old_q if int(q.get("week", 1)) < 19]
    old_q.extend(quests)
    qpath.write_text(json.dumps(old_q, indent=2, ensure_ascii=False) + "\n")

    old_i = json.loads(ipath.read_text())
    for k in list(items.keys()):
        old_i.pop(k, None)
    old_i.update(items)
    ipath.write_text(json.dumps(old_i, indent=2, ensure_ascii=False) + "\n")

    world = json.loads(wpath.read_text())
    buckets = {
        "npc-builder": [],
        "npc-scribe": [],
        "npc-creation": [],
        "npc-chronicle": [],
        "npc-steward": [],
    }
    for q in quests:
        qid = q["id"]
        if "raid" in qid or q["guild"] == "math":
            if q["guild"] == "math" or "raid" in qid:
                buckets["npc-builder"].append(qid)
        if q["guild"] == "la":
            buckets["npc-scribe"].append(qid)
        elif q["guild"] == "science":
            buckets["npc-creation"].append(qid)
        elif q["guild"] == "history":
            buckets["npc-chronicle"].append(qid)
        elif q["guild"] == "bible":
            buckets["npc-steward"].append(qid)

    # Fix builder: math + raids only (raids are guild math already)
    buckets["npc-builder"] = [q["id"] for q in quests if q["guild"] == "math"]

    for npc in world["npcs"]:
        npc["quest_ids"] = [x for x in npc["quest_ids"] if week_num(x) < 19]
        npc["quest_ids"].extend(buckets.get(npc["id"], []))
        print(npc["id"], len(npc["quest_ids"]))

    wpath.write_text(json.dumps(world, indent=2, ensure_ascii=False) + "\n")
    print(f"OK: {len(old_q)} quests, {len(old_i)} items, weeks",
          sorted({int(q['week']) for q in old_q}))

if __name__ == "__main__":
    main()
