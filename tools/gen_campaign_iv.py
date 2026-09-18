#!/usr/bin/env python3
"""Generate Campaign IV (Weeks 28-36) for Lumenstone Godot — Light for the Realm."""
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

def add_q(*args, **kwargs):
    q = quest(*args, **kwargs)
    quests.append(q)
    return q


# ========== WEEK 28 — Mastery Mills ==========
add_q(
    "w28-bible-fruit-start", "Fruit of the Spirit Begins", 28, 1, "bible",
    "Bible — Galatians 5:22–23 & Self-Control",
    "\"The fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control.\"",
    [dlg(SB, "Galatians 5:22–23: the Spirit grows good fruit in us — begin memorizing the list."),
     dlg(SB, "Virtue: Self-control. Masters mill careful habits before festival.")],
    [mc("w28b1", "Galatians 5:22–23 lists the…",
        ["fruit of the Spirit", "names of Texas rivers only", "multiplication tables", "planets to worship"],
        "fruit of the Spirit"),
     mc("w28b2", "Self-control means…",
        ["guiding words and actions wisely", "never feeling anything", "yelling louder", "skipping practice"],
        "guiding words and actions wisely"),
     mc("w28b3", "Which belongs in the fruit list?",
        ["love, joy, peace", "greed, pride, spite", "luck charms", "empty boasts"],
        "love, joy, peace"),
     tf("w28b4", "True or False: Christians ask God to grow good fruit in their hearts."),
     mc("w28b5", "Self-control helps an apprentice…",
        ["finish hard practice without quitting in anger", "mock others", "cheat on facts", "ignore Scripture"],
        "finish hard practice without quitting in anger"),
     mc("w28b6", "Who wrote Galatians?", ["Paul", "Sam Houston", "a bar graph", "a yardstick"], "Paul")],
    "self_control_band", 10)
add_item("self_control_band", "Self-Control Band", "A plain band for Galatians fruit and careful habits.", "accessory", "#c9b037", "w28-bible-fruit-start")

add_q(
    "w28-math-fluency", "Mastery Mills Fluency", 28, 2, "math",
    "Math — ×0–12 Fluency Clinic & Related ÷",
    "\"Mill the facts until they shine — times tables and related division.\"",
    [dlg(MB, "Full ×0–12 fluency. Weak facts get clinic time. Related division: if 7×8=56, then 56÷8=7."),
     dlg(MB, "Self-control: slow and accurate first, then speed.")],
    [fb("w28m1", "7 × 8 =", "56"), fb("w28m2", "9 × 6 =", "54"), fb("w28m3", "12 × 4 =", "48"),
     fb("w28m4", "0 × 11 =", "0"), fb("w28m5", "56 ÷ 8 =", "7"), fb("w28m6", "54 ÷ 9 =", "6"),
     fb("w28m7", "8 × 8 =", "64"), fb("w28m8", "11 × 11 =", "121"), fb("w28m9", "72 ÷ 8 =", "9"),
     tf("w28m10", "True or False: Knowing × facts helps with related ÷ facts.")],
    "fluency_millstone", 12)
add_item("fluency_millstone", "Fluency Millstone", "A small millstone token for ×0–12 clinic mastery.", "belt", "#d4a017", "w28-math-fluency")

add_q(
    "w28-la-grammar", "Grammar Bootcamp Hall", 28, 3, "la",
    "LA — Sentences, Nouns/Verbs/Adjectives, Punctuation",
    "\"Polish sentences: subjects, verbs, adjectives, and end marks.\"",
    [dlg(MS, "Bootcamp: complete sentences, nouns, verbs, adjectives, capitals, periods/questions/exclamations."),
     dlg(MS, "Clear writing serves neighbors well.")],
    [mc("w28l1", "A complete sentence needs…",
        ["a subject and a predicate (verb part)", "only a noun", "only an adjective", "no words"],
        "a subject and a predicate (verb part)"),
     mc("w28l2", "Which word is a noun?", ["Texas", "quickly", "run", "beautiful"], "Texas"),
     mc("w28l3", "Which word is a verb?", ["builds", "blue", "lamp", "joy"], "builds"),
     mc("w28l4", "Which word is an adjective?", ["bright", "ran", "Houston", "and"], "bright"),
     mc("w28l5", "A question ends with…", ["?", ".", "!", ","], "?"),
     tf("w28l6", "True or False: Sentences should start with a capital letter."),
     mc("w28l7", "Punctuation helps readers…",
        ["know where ideas start and stop", "skip reading", "erase meaning", "worship commas"],
        "know where ideas start and stop")],
    "grammar_quill", 10)
add_item("grammar_quill", "Grammar Quill", "A quill for sentence and punctuation bootcamp.", "accessory", "#3a6ea5", "w28-la-grammar")

add_q(
    "w28-science-project-choice", "Nature Project Choice", 28, 4, "science",
    "Science — Choose a Creation-Science Nature Project",
    "\"Pick a nature topic that honors the Creator — then plan to study it.\"",
    [dlg(SC, "Choose a project: plants, birds, weather, rocks, insects, habitats — creation-honoring."),
     dlg(SC, "Wonder and careful observation beat guessing.")],
    [mc("w28s1", "A good creation-science project…",
        ["studies real nature with gratitude to the Creator", "worships nature as god", "ignores observation", "only copies games"],
        "studies real nature with gratitude to the Creator"),
     mc("w28s2", "Before experimenting you should…",
        ["choose a clear question and plan", "skip all planning", "guess forever", "never write notes"],
        "choose a clear question and plan"),
     mc("w28s3", "A nature journal helps you…",
        ["record observations over time", "erase creation", "skip facts", "only draw nonsense"],
        "record observations over time"),
     tf("w28s4", "True or False: Plants, weather, and habitats can all be worthy project topics."),
     mc("w28s5", "Stewardship in a project means…",
        ["care for creatures and places while you study", "litter for fun", "harm habitats", "never thank God"],
        "care for creatures and places while you study"),
     mc("w28s6", "A fair test tries to…",
        ["change one thing carefully and watch results", "change everything at once with no notes", "never measure", "hide results"],
        "change one thing carefully and watch results")],
    "project_choice_token", 10)
add_item("project_choice_token", "Project Choice Token", "A token marking your chosen nature project topic.", "accessory", "#2d6a4f", "w28-science-project-choice")

add_q(
    "w28-history-us-retell", "Five Scenes of the States", 28, 5, "history",
    "History — US Story Retell in 5 Scenes",
    "\"Draw and caption five scenes that tell the American story so far.\"",
    [dlg(CK, "Retell in five scenes: Indigenous peoples, colonies, Revolution, Constitution, early growth — age-right."),
     dlg(CK, "Captions should be true and respectful.")],
    [mc("w28h1", "A five-scene US retell might include…",
        ["colonies, Revolution, and Constitution ideas", "only game bosses", "only fractions", "only moon phases"],
        "colonies, Revolution, and Constitution ideas"),
     mc("w28h2", "The Declaration is tied to…",
        ["American independence ideals", "Texas bluebonnets only", "yardsticks", "÷ remainders"],
        "American independence ideals"),
     mc("w28h3", "The Constitution helps by…",
        ["setting a framework of laws and rights", "erasing all laws", "naming planets as gods", "replacing arithmetic"],
        "setting a framework of laws and rights"),
     tf("w28h4", "True or False: Indigenous peoples lived in North America long before the thirteen colonies."),
     mc("w28h5", "Captions on history scenes should be…",
        ["factual and respectful", "mean jokes only", "blank forever", "pure guesswork"],
        "factual and respectful"),
     mc("w28h6", "Why retell history in scenes?",
        ["to remember the story clearly", "to forget the past", "to skip maps", "to avoid virtues"],
        "to remember the story clearly")],
    "us_scene_scroll", 10)
add_item("us_scene_scroll", "US Scene Scroll", "A scroll for five captioned US history scenes.", "accessory", "#9b2226", "w28-history-us-retell")

add_q(
    "w28-raid-review", "Raid Review: Mastery Mills", 28, 5, "math",
    "Friday Raid — Week 28 Mixed Review",
    "\"Prove fluency, grammar, project choice, US scenes, and Fruit of the Spirit.\"",
    [dlg(HS, "Week 28 proving. Mastery ≥80%."),
     dlg(HS, "Mill facts with self-control; polish words; honor creation and history.")],
    [fb("w28r1", "8 × 7 =", "56"), fb("w28r2", "63 ÷ 9 =", "7"),
     mc("w28r3", "A complete sentence needs…",
        ["subject and verb part", "only commas forever", "no capitals", "only adjectives"],
        "subject and verb part"),
     mc("w28r4", "A nature project should…",
        ["honor the Creator with careful study", "worship nature", "skip notes", "hide results"],
        "honor the Creator with careful study"),
     mc("w28r5", "US retell scenes may include…",
        ["Revolution and Constitution", "only cape colors", "only ounces", "only soft c"],
        "Revolution and Constitution"),
     mc("w28r6", "Fruit of the Spirit includes…",
        ["love, joy, peace, self-control", "greed and spite", "luck charms", "random noise"],
        "love, joy, peace, self-control"),
     tf("w28r7", "True or False: Self-control helps with timed fact practice."),
     fb("w28r8", "12 × 5 =", "60")],
    "mills_cloak", 30)
add_item("mills_cloak", "Mills Cloak", "Cloak earned at the Mastery Mills review.", "cape", "#d4a017", "w28-raid-review")

# ========== WEEK 29 — Problem-Solvers Path ==========
add_q(
    "w29-bible-patience", "Patience on the Path", 29, 1, "bible",
    "Bible — Fruit Continued & Patience",
    "\"Keep memorizing the fruit; practice patience when problems take time.\"",
    [dlg(SB, "Continue Galatians 5:22–23. Add virtue focus: Patience — waiting and working without harshness."),
     dlg(SB, "Multi-step problems and drafts both need patient hearts.")],
    [mc("w29b1", "Patience means…",
        ["waiting and working calmly without harshness", "quitting at once", "mocking slow work", "skipping hard steps"],
        "waiting and working calmly without harshness"),
     mc("w29b2", "The fruit list includes…",
        ["patience and kindness", "cruelty", "chaos as lord", "only money"],
        "patience and kindness"),
     tf("w29b3", "True or False: God is patient with His people."),
     mc("w29b4", "When a story problem is long you should…",
        ["read carefully and take one step at a time", "guess angrily", "erase the question", "never try"],
        "read carefully and take one step at a time"),
     mc("w29b5", "Fruit of the Spirit comes from…",
        ["the Holy Spirit's work in believers", "luck charms", "cape fashion alone", "empty boasts"],
        "the Holy Spirit's work in believers")],
    "patience_pin", 10)
add_item("patience_pin", "Patience Pin", "A pin for patient problem-solving and fruit memory.", "accessory", "#c9b037", "w29-bible-patience")

add_q(
    "w29-math-multistep", "Problem-Solvers Path", 29, 2, "math",
    "Math — Multi-Step Lumenstone Story Problems",
    "\"Read the tale, choose operations, solve step by step.\"",
    [dlg(MB, "Multi-step stories: find what you know, what you need, then compute in order."),
     dlg(MB, "Patience beats rushing past a key word like 'altogether' or 'left'.")],
    [fb("w29m1", "A steward packs 3 crates of 8 lamps, then gives away 5. How many lamps left?", "19"),
     fb("w29m2", "4 shelves hold 6 books each. Add 3 more books. Total books?", "27"),
     fb("w29m3", "A baker makes 5 dozen rolls (12 each). How many rolls?", "60"),
     fb("w29m4", "60 rolls shared equally among 5 families. Each family gets?", "12"),
     fb("w29m5", "A path is 9 yards. How many feet? (3 ft = 1 yd)", "27"),
     mc("w29m6", "First step for a multi-step story is often…",
        ["understand the question and list facts", "guess the answer only", "skip reading", "draw only pictures"],
        "understand the question and list facts"),
     fb("w29m7", "2 packs of 7 stickers, then −3 =", "11"),
     tf("w29m8", "True or False: Checking your last step is wise.")],
    "solver_abacus", 12)
add_item("solver_abacus", "Solver Abacus", "An abacus for multi-step story problem practice.", "belt", "#d4a017", "w29-math-multistep")

add_q(
    "w29-la-process", "Writing Process Path", 29, 3, "la",
    "LA — Plan → Draft → Revise → Edit → Publish",
    "\"Walk the full writing path before the hall publishes.\"",
    [dlg(MS, "Process: plan ideas, draft freely, revise for clarity, edit mechanics, then publish."),
     dlg(MS, "Patience: good writing rarely arrives in one perfect pass.")],
    [mc("w29l1", "Planning comes…", ["before drafting", "only after publishing", "never", "only in math"], "before drafting"),
     mc("w29l2", "Revising mainly improves…",
        ["ideas, order, and clarity", "only ink color", "only page count", "cape length"],
        "ideas, order, and clarity"),
     mc("w29l3", "Editing checks…",
        ["spelling, capitals, punctuation", "only habitat names", "only ounces", "only review XP"],
        "spelling, capitals, punctuation"),
     mc("w29l4", "Publishing means…",
        ["sharing a finished piece with readers", "hiding the draft forever", "skipping edit", "never reading aloud"],
        "sharing a finished piece with readers"),
     tf("w29l5", "True or False: Drafting allows imperfect first words."),
     mc("w29l6", "A helpful plan might include…",
        ["topic, audience, and key points", "only random scribbles with no topic", "only blank pages", "no audience thought"],
        "topic, audience, and key points")],
    "process_folio", 10)
add_item("process_folio", "Process Folio", "A folio marking plan-draft-revise-edit-publish.", "accessory", "#3a6ea5", "w29-la-process")

add_q(
    "w29-science-plan", "Experiment Plan Scroll", 29, 4, "science",
    "Science — Project Research & Experiment Plan",
    "\"Research your topic; write a fair-test plan before you run it.\"",
    [dlg(SC, "Research trusted facts; write question, materials, steps, and what you will measure."),
     dlg(SC, "Creation-honoring conclusions thank the Designer — they do not invent myths.")],
    [mc("w29s1", "An experiment plan should include…",
        ["question, materials, steps, and what to measure", "only a title with no steps", "luck charms", "no safety thought"],
        "question, materials, steps, and what to measure"),
     mc("w29s2", "Research before testing helps you…",
        ["ask a clearer question", "skip all reading", "guess forever", "ignore creation"],
        "ask a clearer question"),
     mc("w29s3", "A fair test usually changes…",
        ["one main variable carefully", "every variable at once", "nothing ever", "only the notebook cover"],
        "one main variable carefully"),
     tf("w29s4", "True or False: Safety and stewardship matter in nature projects."),
     mc("w29s5", "Recording a prediction means…",
        ["writing what you think may happen before the test", "erasing all results", "never measuring", "hiding the plan"],
        "writing what you think may happen before the test"),
     mc("w29s6", "A creation-honoring project…",
        ["studies God's world with honesty and wonder", "denies a Creator by rule", "worships weather", "skips observation"],
        "studies God's world with honesty and wonder")],
    "experiment_plan_scroll", 10)
add_item("experiment_plan_scroll", "Experiment Plan Scroll", "A scroll for research notes and experiment steps.", "accessory", "#2d6a4f", "w29-science-plan")

add_q(
    "w29-history-tx-retell", "Five Scenes of Texas", 29, 5, "history",
    "History — Texas Story Retell in 5 Scenes",
    "\"Draw and caption five scenes of the Texas story.\"",
    [dlg(CK, "Five scenes: Indigenous Texas, Spanish/missions, Mexican Texas, Revolution, Republic→statehood."),
     dlg(CK, "Texas pride with humility — thank God for home and neighbors.")],
    [mc("w29h1", "Texas Independence era includes…",
        ["the Alamo and San Jacinto", "the moon landing as a Texas battle", "inventing fractions", "writing Galatians"],
        "the Alamo and San Jacinto"),
     mc("w29h2", "Before statehood Texas was a…", ["republic", "planet", "constellation", "gallon"], "republic"),
     mc("w29h3", "Spanish Texas is remembered partly for…",
        ["missions and early settlements", "inventing the US Constitution alone", "× tables", "soft g only"],
        "missions and early settlements"),
     tf("w29h4", "True or False: Indigenous peoples lived in Texas before Spanish explorers."),
     mc("w29h5", "Texas became a US state in…", ["1845", "1776", "1492", "2000"], "1845"),
     mc("w29h6", "A respectful Texas retell…",
        ["tells hard and hopeful parts with care", "erases all people groups", "only jokes", "skips maps forever"],
        "tells hard and hopeful parts with care")],
    "texas_scene_scroll", 10)
add_item("texas_scene_scroll", "Texas Scene Scroll", "A scroll for five captioned Texas history scenes.", "accessory", "#9b2226", "w29-history-tx-retell")

add_q(
    "w29-raid-review", "Raid Review: Problem-Solvers Path", 29, 5, "math",
    "Friday Raid — Week 29 Mixed Review",
    "\"Prove multi-step math, writing process, experiment plans, Texas scenes, patience.\"",
    [dlg(HS, "Week 29 proving. Mastery ≥80%."),
     dlg(HS, "Patient steps solve long problems and long drafts.")],
    [fb("w29r1", "3 crates of 8, then −5 lamps left?", "19"), fb("w29r2", "5×12 =", "60"),
     mc("w29r3", "Writing process order starts with…", ["plan", "publish first", "edit only", "never draft"], "plan"),
     mc("w29r4", "Experiment plans need…",
        ["steps and what to measure", "no question", "luck charms", "hidden results only"],
        "steps and what to measure"),
     mc("w29r5", "Texas statehood year?", ["1845", "1836 only forever", "1620", "1914"], "1845"),
     mc("w29r6", "Patience is part of…",
        ["the fruit of the Spirit", "skipping practice", "cruelty", "chaos worship"],
        "the fruit of the Spirit"),
     tf("w29r7", "True or False: Revising improves clarity."),
     fb("w29r8", "9 yards = ____ feet", "27")],
    "solvers_cloak", 30)
add_item("solvers_cloak", "Solvers Cloak", "Cloak earned at the Problem-Solvers Path review.", "cape", "#b08968", "w29-raid-review")

# ========== WEEK 30 — Publishers of the Hall ==========
add_q(
    "w30-bible-joy", "Rejoice Always", 30, 1, "bible",
    "Bible — 1 Thessalonians 5:16–18 & Joy",
    "\"Rejoice always, pray without ceasing, give thanks in all circumstances.\"",
    [dlg(SB, "1 Thessalonians 5:16–18: rejoice, pray, give thanks — joy is deeper than a mood."),
     dlg(SB, "Virtue: Joy. Publishers celebrate finished work with gratitude.")],
    [mc("w30b1", "1 Thessalonians 5:16–18 calls us to…",
        ["rejoice, pray, and give thanks", "grumble only", "never pray", "hide gratitude"],
        "rejoice, pray, and give thanks"),
     mc("w30b2", "Joy as a fruit means…",
        ["glad trust in God, not only easy feelings", "never smiling", "mocking others", "skipping thanks"],
        "glad trust in God, not only easy feelings"),
     tf("w30b3", "True or False: We can give thanks even on hard days."),
     mc("w30b4", "Publishing writing can be a time to…",
        ["thank God for words and helpers", "boast cruelly", "hide all work", "insult readers"],
        "thank God for words and helpers"),
     mc("w30b5", "Who wrote 1 Thessalonians?", ["Paul", "Austin", "a rain gauge", "Neptune"], "Paul")],
    "joy_ribbon", 10)
add_item("joy_ribbon", "Joy Ribbon", "A ribbon for rejoicing and giving thanks.", "accessory", "#c9b037", "w30-bible-joy")

add_q(
    "w30-math-frac-measure", "Fraction & Measure Stations", 30, 2, "math",
    "Math — Fractions Review + Measurement Review",
    "\"Station day: parts of a whole, like-denominator add, length/weight/capacity.\"",
    [dlg(MB, "Review: fractions of a set, compare, add like denominators; inches/feet/yards; oz/lb; cups to gallons."),
     dlg(MB, "Joy in mastery comes after honest practice.")],
    [fb("w30m1", "1/4 of 12 =", "3"), fb("w30m2", "2/5 + 1/5 =", "3/5"), fb("w30m3", "3/8 + 2/8 =", "5/8"),
     fb("w30m4", "36 inches = ____ yard(s)", "1"), fb("w30m5", "16 ounces = ____ pound(s)", "1"),
     fb("w30m6", "4 quarts = ____ gallon(s)", "1"),
     mc("w30m7", "Which is larger?", ["3/4", "1/4", "they are equal", "neither is a fraction"], "3/4"),
     tf("w30m8", "True or False: Like denominators make fraction addition simpler."),
     fb("w30m9", "2 feet = ____ inches", "24")],
    "station_ruler", 12)
add_item("station_ruler", "Station Ruler", "A ruler for fraction and measurement review stations.", "belt", "#d4a017", "w30-math-frac-measure")

add_q(
    "w30-la-publish", "Publishers of the Hall", 30, 3, "la",
    "LA — Publish Final Writing; Read Aloud",
    "\"Bind the booklet; read aloud to family with clear voice.\"",
    [dlg(MS, "Publish: neat final copy, cover, and read-aloud practice — eye contact and kind volume."),
     dlg(MS, "Joy shared is joy multiplied.")],
    [mc("w30l1", "Publishing a booklet usually includes…",
        ["a neat final copy readers can enjoy", "only messy scratch paper forever", "no title", "hidden pages"],
        "a neat final copy readers can enjoy"),
     mc("w30l2", "Reading aloud well means…",
        ["clear voice and respectful pace", "mumbling only", "yelling unkindly", "skipping all words"],
        "clear voice and respectful pace"),
     mc("w30l3", "A cover helps by…",
        ["naming the piece and inviting readers", "hiding the topic", "replacing the story", "erasing punctuation"],
        "naming the piece and inviting readers"),
     tf("w30l4", "True or False: Thanking listeners is polite."),
     mc("w30l5", "Before reading aloud, check…",
        ["hard words and punctuation pauses", "only cape color", "only page glitter", "nothing"],
        "hard words and punctuation pauses"),
     mc("w30l6", "Family read-alouds build…",
        ["confidence and shared joy", "fear of words", "hatred of books", "chaos"],
        "confidence and shared joy")],
    "published_booklet", 12)
add_item("published_booklet", "Published Booklet", "A finished booklet token for the hall publishers.", "accessory", "#3a6ea5", "w30-la-publish")

add_q(
    "w30-science-experiment", "Run the Experiment", 30, 4, "science",
    "Science — Conduct Experiment; Record Results",
    "\"Follow the plan; record what happens; stay honest.\"",
    [dlg(SC, "Run the experiment safely. Record observations and results in the journal — even surprises."),
     dlg(SC, "Honest data honors the Creator of a real world.")],
    [mc("w30s1", "While running a test you should…",
        ["follow steps and record results", "guess and skip notes", "change the plan secretly mid-way with no record", "never measure"],
        "follow steps and record results"),
     mc("w30s2", "If results surprise you…",
        ["write them honestly anyway", "erase them", "invent nicer numbers", "quit science forever"],
        "write them honestly anyway"),
     mc("w30s3", "A journal entry may include…",
        ["date, observations, and measurements", "only doodles", "no date ever", "only PIN codes"],
        "date, observations, and measurements"),
     tf("w30s4", "True or False: Safety gear and careful handling matter during experiments."),
     mc("w30s5", "Comparing prediction to results helps you…",
        ["learn what the test showed", "hide learning", "skip thinking", "worship tools"],
        "learn what the test showed"),
     mc("w30s6", "Stewardship during labs means…",
        ["clean up and care for materials and living things", "litter the hall", "waste water for fun", "harm creatures"],
        "clean up and care for materials and living things")],
    "results_journal", 10)
add_item("results_journal", "Results Journal", "A journal for experiment observations and data.", "accessory", "#2d6a4f", "w30-science-experiment")

add_q(
    "w30-history-timelines", "Timelines Side by Side", 30, 5, "history",
    "History — Compare US & Texas Timelines",
    "\"Lay US and Texas timelines together; notice connections.\"",
    [dlg(CK, "Compare: colonies/Revolution/Constitution beside Spanish Texas, Revolution, Republic, 1845 statehood."),
     dlg(CK, "Joy in home and nation — with humility before God.")],
    [mc("w30h1", "Texas statehood (1845) comes…",
        ["after the US Constitution era", "before all Indigenous peoples", "before 1492", "in year 1 only"],
        "after the US Constitution era"),
     mc("w30h2", "Side-by-side timelines help you…",
        ["see what happened around the same seasons of history", "erase Texas", "skip dates", "ban maps"],
        "see what happened around the same seasons of history"),
     mc("w30h3", "US Independence is associated with…",
        ["1776 Declaration era", "1845 only", "Texas bluebonnet law only", "Galatians alone"],
        "1776 Declaration era"),
     tf("w30h4", "True or False: Texas was once its own republic before joining the United States."),
     mc("w30h5", "A timeline should be…",
        ["ordered by time with clear labels", "random scribbles only", "secret forever", "only cape colors"],
        "ordered by time with clear labels"),
     mc("w30h6", "Comparing timelines builds…",
        ["understanding of how stories connect", "confusion on purpose", "hatred of home", "skipping virtues"],
        "understanding of how stories connect")],
    "dual_timeline_card", 10)
add_item("dual_timeline_card", "Dual Timeline Card", "A card comparing US and Texas timelines.", "accessory", "#9b2226", "w30-history-timelines")

add_q(
    "w30-raid-review", "Raid Review: Publishers of the Hall", 30, 5, "math",
    "Friday Raid — Week 30 Mixed Review",
    "\"Prove fractions, measurement, publishing, experiments, timelines, joy.\"",
    [dlg(HS, "Week 30 proving. Mastery ≥80%."),
     dlg(HS, "Publish with joy; measure honestly; thank God.")],
    [fb("w30r1", "1/3 of 9 =", "3"), fb("w30r2", "2/7 + 3/7 =", "5/7"), fb("w30r3", "3 feet = ____ yard(s)", "1"),
     mc("w30r4", "Publishing includes…",
        ["a neat final copy", "only trash drafts", "no reading aloud ever", "hidden covers only"],
        "a neat final copy"),
     mc("w30r5", "Honest experiment records…",
        ["write what really happened", "invent only perfect data", "erase surprises", "skip dates"],
        "write what really happened"),
     mc("w30r6", "1 Thessalonians 5:16–18 includes…",
        ["rejoice and give thanks", "never pray", "grumble always", "hide joy"],
        "rejoice and give thanks"),
     tf("w30r7", "True or False: Texas joined the US in 1845."),
     fb("w30r8", "16 oz = ____ lb", "1")],
    "publishers_cloak", 30)
add_item("publishers_cloak", "Publishers Cloak", "Cloak earned at the Publishers of the Hall review.", "cape", "#3a6ea5", "w30-raid-review")

# ========== WEEK 31 — Geometry Jubilee ==========
add_q(
    "w31-bible-thanks", "Psalm 100 Thanksgiving", 31, 1, "bible",
    "Bible — Psalm 100 & Thankfulness",
    "\"Enter His gates with thanksgiving and His courts with praise.\"",
    [dlg(SB, "Psalm 100: shout joyfully, serve gladly, know the Lord is God — give thanks."),
     dlg(SB, "Virtue: Thankfulness. Geometry jubilee is a time to thank the Order-Maker.")],
    [mc("w31b1", "Psalm 100 calls us to…",
        ["thanksgiving and praise", "grumbling only", "silence forever about God", "pride as worship"],
        "thanksgiving and praise"),
     mc("w31b2", "Thankfulness means…",
        ["noticing gifts and saying thank you to God and people", "never noticing kindness", "demanding more only", "mocking helpers"],
        "noticing gifts and saying thank you to God and people"),
     tf("w31b3", "True or False: We can thank God for ordered shapes and measures in creation."),
     mc("w31b4", "\"The Lord is God\" in Psalm 100 reminds us…",
        ["He made us; we belong to Him", "we made ourselves as gods", "math replaces God", "thanks is optional forever"],
        "He made us; we belong to Him"),
     mc("w31b5", "Serving with gladness looks like…",
        ["helpful work with a willing heart", "helping only when paid in capes", "refusing chores", "insulting family"],
        "helpful work with a willing heart")],
    "thanks_seal", 10)
add_item("thanks_seal", "Thanks Seal", "A seal for Psalm 100 and thankful habits.", "accessory", "#c9b037", "w31-bible-thanks")

add_q(
    "w31-math-geometry", "Geometry Jubilee Games", 31, 2, "math",
    "Math — Shapes, Perimeter, Area; Optional Volume Idea",
    "\"Play shape games; compute perimeter and area; peek at volume with blocks.\"",
    [dlg(MB, "Name shapes; perimeter = distance around; area = square units inside. Optional: count cubes for volume idea."),
     dlg(MB, "Thankfulness: ordered measure reflects a wise Maker.")],
    [fb("w31m1", "Perimeter of a square side 5?", "20"), fb("w31m2", "Area of a 6×4 rectangle?", "24"),
     fb("w31m3", "Perimeter of a 6×4 rectangle?", "20"), fb("w31m4", "Area of a square side 7?", "49"),
     mc("w31m5", "A triangle has how many sides?", ["3", "4", "5", "8"], "3"),
     mc("w31m6", "Volume with cubes is about…",
        ["how much space a solid holds (count of cubes)", "only color", "only perimeter forever", "only Texas rivers"],
        "how much space a solid holds (count of cubes)"),
     fb("w31m7", "If 2 layers of 3×4 cubes, how many cubes?", "24"),
     tf("w31m8", "True or False: Area and perimeter are different measures.")],
    "jubilee_compass", 12)
add_item("jubilee_compass", "Jubilee Compass", "A compass for shape and measure jubilee games.", "belt", "#d4a017", "w31-math-geometry")

add_q(
    "w31-la-poetry", "Poetry Cafe", 31, 3, "la",
    "LA — Write & Perform Short Poems",
    "\"Write short poems; share them in the cafe with kind listeners.\"",
    [dlg(MS, "Poetry cafe: imagery, rhythm, simile/metaphor light touch, clear performance."),
     dlg(MS, "Thankfulness poems may praise Creator and gifts.")],
    [mc("w31l1", "A poem often uses…",
        ["careful word choice and rhythm or line breaks", "only tax forms", "only long division", "no words"],
        "careful word choice and rhythm or line breaks"),
     mc("w31l2", "A simile usually compares using…", ["like or as", "only numbers", "only maps", "empty boasts"], "like or as"),
     mc("w31l3", "Performing a poem well includes…",
        ["clear voice and respectful audience manners", "shouting over others", "never practicing", "hiding the page forever"],
        "clear voice and respectful audience manners"),
     tf("w31l4", "True or False: Poems can thank God for creation."),
     mc("w31l5", "Line breaks in poetry can…",
        ["shape rhythm and emphasis", "erase meaning always", "replace spelling rules forever", "ban thankfulness"],
        "shape rhythm and emphasis"),
     mc("w31l6", "Listeners at a poetry cafe should…",
        ["listen kindly and clap politely", "mock every line", "talk over the reader", "leave mid-line rudely"],
        "listen kindly and clap politely")],
    "poetry_cafe_card", 10)
add_item("poetry_cafe_card", "Poetry Cafe Card", "A card for writing and sharing short poems.", "accessory", "#3a6ea5", "w31-la-poetry")

add_q(
    "w31-science-display", "Project Display Board", 31, 4, "science",
    "Science — Finish Project Display (Poster/Tri-Fold)",
    "\"Build a clear display: question, method, results, creation-honoring conclusion.\"",
    [dlg(SC, "Finish the poster or tri-fold: title, question, steps, data, conclusion that honors the Creator."),
     dlg(SC, "Neat labels help visitors learn.")],
    [mc("w31s1", "A strong project display shows…",
        ["question, method, results, and conclusion", "only a title with no data", "hidden results", "luck charms"],
        "question, method, results, and conclusion"),
     mc("w31s2", "A creation-honoring conclusion might…",
        ["thank God for order observed in nature", "deny design by rule", "worship the display board", "skip honesty"],
        "thank God for order observed in nature"),
     mc("w31s3", "Labels and headings help…",
        ["visitors find information quickly", "confuse readers on purpose", "erase data", "ban questions"],
        "visitors find information quickly"),
     tf("w31s4", "True or False: Pictures and graphs can support your results."),
     mc("w31s5", "Before fair day, check…",
        ["spelling on labels and that data matches the journal", "only cape color", "only glitter", "nothing"],
        "spelling on labels and that data matches the journal"),
     mc("w31s6", "Stewardship on display day includes…",
        ["truthful claims and tidy setup", "exaggerating wildly", "littering the hall", "hiding helpers' names spitefully"],
        "truthful claims and tidy setup")],
    "display_board_kit", 10)
add_item("display_board_kit", "Display Board Kit", "Kit token for finishing a science project display.", "accessory", "#2d6a4f", "w31-science-display")

add_q(
    "w31-history-maps", "Map Mastery Hall", 31, 5, "history",
    "History — US Regions & Texas Cities/Rivers",
    "\"Label regions, cities, and rivers — know your maps.\"",
    [dlg(CK, "Map mastery: US regions; Texas cities (e.g. Austin, Houston, Dallas, San Antonio); rivers like the Rio Grande."),
     dlg(CK, "Thankfulness for land and neighbors.")],
    [mc("w31h1", "Austin is the…",
        ["capital city of Texas", "capital of every nation", "a planet", "a fraction"],
        "capital city of Texas"),
     mc("w31h2", "The Rio Grande is a…",
        ["major river along part of the Texas border", "mountain only", "moon", "spelling rule"],
        "major river along part of the Texas border"),
     mc("w31h3", "US map regions help you…",
        ["group states by area of the country", "erase borders", "skip geography", "replace history"],
        "group states by area of the country"),
     tf("w31h4", "True or False: Houston and Dallas are major Texas cities."),
     mc("w31h5", "San Antonio is known partly for…",
        ["missions and Texas Revolution memory (Alamo)", "being the moon's capital", "inventing ÷", "writing Psalm 100"],
        "missions and Texas Revolution memory (Alamo)"),
     mc("w31h6", "Map labels should be…",
        ["clear and accurate", "random scribbles only", "secret codes only", "blank forever"],
        "clear and accurate")],
    "map_mastery_pin", 10)
add_item("map_mastery_pin", "Map Mastery Pin", "A pin for US regions and Texas map practice.", "accessory", "#9b2226", "w31-history-maps")

add_q(
    "w31-raid-review", "Raid Review: Geometry Jubilee", 31, 5, "math",
    "Friday Raid — Week 31 Mixed Review",
    "\"Prove geometry, poetry, displays, maps, Psalm 100 thankfulness.\"",
    [dlg(HS, "Week 31 proving. Mastery ≥80%."),
     dlg(HS, "Jubilee: measure with thanks; speak poems; know your maps.")],
    [fb("w31r1", "Perimeter of square side 6?", "24"), fb("w31r2", "Area of 5×3?", "15"),
     mc("w31r3", "Poetry cafe sharing should be…", ["clear and kind", "rude", "silent forever", "false"], "clear and kind"),
     mc("w31r4", "Project displays need…",
        ["question, method, results, conclusion", "no data", "luck charms", "hidden titles only"],
        "question, method, results, conclusion"),
     mc("w31r5", "Texas capital city?", ["Austin", "Neptune", "Philadelphia only", "London"], "Austin"),
     mc("w31r6", "Psalm 100 emphasizes…",
        ["thanksgiving and praise", "grumbling", "pride as lord", "skipping worship"],
        "thanksgiving and praise"),
     tf("w31r7", "True or False: Area counts square units inside a shape."),
     fb("w31r8", "Perimeter of 5×3 rectangle?", "16")],
    "jubilee_cloak", 30)
add_item("jubilee_cloak", "Jubilee Cloak", "Cloak earned at the Geometry Jubilee review.", "cape", "#2d6a4f", "w31-raid-review")

# ========== WEEK 32 — Steward Science Fair ==========
add_q(
    "w32-bible-goodness", "Let Your Light Shine", 32, 1, "bible",
    "Bible — Matthew 5:16 & Goodness",
    "\"Let your light shine before others, that they may see your good works and give glory to your Father.\"",
    [dlg(SB, "Matthew 5:16: shine with good works so people glorify the Father — not so we boast."),
     dlg(SB, "Virtue: Goodness. Science fair light points to the Creator.")],
    [mc("w32b1", "Matthew 5:16 says let your light…",
        ["shine before others", "hide under fear forever", "mock neighbors", "replace God"],
        "shine before others"),
     mc("w32b2", "Good works should lead people to…",
        ["give glory to the Father", "worship the student as a god", "hate learning", "hide truth"],
        "give glory to the Father"),
     mc("w32b3", "Goodness means…",
        ["doing what is right and kind", "cruel show-off", "cheating for praise", "ignoring helpers"],
        "doing what is right and kind"),
     tf("w32b4", "True or False: Sharing a creation-honoring project can be a way to let light shine."),
     mc("w32b5", "Boasting pridefully…",
        ["steals glory that belongs to God", "is required at every fair", "is the fruit of the Spirit", "replaces thank-yous"],
        "steals glory that belongs to God")],
    "goodness_lamp", 10)
add_item("goodness_lamp", "Goodness Lamp", "A small lamp for Matthew 5:16 and good works.", "accessory", "#c9b037", "w32-bible-goodness")

add_q(
    "w32-math-graphs", "Project Data Graphs", 32, 2, "math",
    "Math — Graph Project Data; Word-Problem Review",
    "\"Turn your measurements into a clear graph; review story problems.\"",
    [dlg(MB, "Use tallies or tables from your project; make a bar or picture graph; answer questions from it."),
     dlg(MB, "Goodness includes honest scales — do not stretch bars to impress.")],
    [fb("w32m1", "If one star = 2 and 5 stars show, total?", "10"),
     fb("w32m2", "Bar for Monday=4, Tuesday=6. How many more on Tuesday?", "2"),
     fb("w32m3", "3 + 5 + 2 =", "10"),
     fb("w32m4", "A graph key says each box = 3. Four boxes show?", "12"),
     mc("w32m5", "A fair graph should…",
        ["match the real data", "invent taller bars for show", "hide the key", "use no labels"],
        "match the real data"),
     fb("w32m6", "2 packs of 6, then +4 =", "16"),
     tf("w32m7", "True or False: Titles and labels help readers understand a graph."),
     fb("w32m8", "1/2 of 10 =", "5")],
    "data_graph_slate", 12)
add_item("data_graph_slate", "Data Graph Slate", "A slate for graphing science project data.", "belt", "#d4a017", "w32-math-graphs")

add_q(
    "w32-la-present", "Presentation & Thank-Yous", 32, 3, "la",
    "LA — Presentation Skills; Thank-You Notes",
    "\"Speak clearly; write thank-yous to helpers and guests.\"",
    [dlg(MS, "Presentation: stand tall, speak clearly, eye contact, answer questions kindly."),
     dlg(MS, "Thank-you notes honor parents, guests, and teachers — goodness in words.")],
    [mc("w32l1", "A strong presentation voice is…",
        ["clear and respectful", "mumbled only", "rude shouting", "silent forever"],
        "clear and respectful"),
     mc("w32l2", "Thank-you notes should…",
        ["name the gift or help and say thanks", "insult the helper", "be blank", "demand more gifts"],
        "name the gift or help and say thanks"),
     mc("w32l3", "When someone asks a question you should…",
        ["listen and answer as honestly as you can", "ignore them", "mock them", "run away always"],
        "listen and answer as honestly as you can"),
     tf("w32l4", "True or False: Practicing once or twice before presenting helps."),
     mc("w32l5", "Eye contact (as able) shows…",
        ["respectful attention", "hatred", "fear of words only", "skipping manners"],
        "respectful attention"),
     mc("w32l6", "A thank-you might begin with…",
        ["Dear… and a clear thanks", "No greeting and a complaint only", "Only numbers", "Only maps"],
        "Dear… and a clear thanks")],
    "thankyou_set", 10)
add_item("thankyou_set", "Thank-You Set", "Cards for presentation practice and thank-you notes.", "accessory", "#3a6ea5", "w32-la-present")

add_q(
    "w32-science-present", "Steward Science Fair", 32, 4, "science",
    "Science — Present Project (Creation-Honoring)",
    "\"Present to family and friends; end with a creation-honoring conclusion.\"",
    [dlg(SC, "Tell your question, what you did, what you found, and thank the Creator for order and wonder."),
     dlg(SC, "Goodness shines when truth and gratitude walk together.")],
    [mc("w32s1", "A creation-honoring presentation should…",
        ["give credit to the Creator for the world studied", "claim you created the laws of nature", "worship the project board", "hide all results"],
        "give credit to the Creator for the world studied"),
     mc("w32s2", "Presentations usually include…",
        ["question, method, results, conclusion", "only jokes with no science", "only cape fashion", "no speaking"],
        "question, method, results, conclusion"),
     mc("w32s3", "If you do not know an answer…",
        ["say so honestly and offer to find out", "invent loudly", "blame guests", "quit forever"],
        "say so honestly and offer to find out"),
     tf("w32s4", "True or False: Guests may ask questions about your methods."),
     mc("w32s5", "Stewardship after the fair includes…",
        ["cleaning up and caring for materials", "leaving a mess", "wasting leftover supplies for fun", "hiding thank-yous"],
        "cleaning up and caring for materials"),
     mc("w32s6", "The point of the fair is…",
        ["share learning and honor creation", "win by unkind pride", "scare guests", "skip science"],
        "share learning and honor creation")],
    "science_fair_ribbon", 12)
add_item("science_fair_ribbon", "Science Fair Ribbon", "A ribbon for presenting a creation-honoring project.", "accessory", "#2d6a4f", "w32-science-present")

add_q(
    "w32-history-museum", "Museum Night Three Facts", 32, 5, "history",
    "History — Oral Museum Night (3 Facts)",
    "\"Teach family three solid history facts like a young docent.\"",
    [dlg(CK, "Museum night: choose three accurate US or Texas facts; teach them clearly."),
     dlg(CK, "Goodness: share knowledge to serve, not to show off.")],
    [mc("w32h1", "A good museum-night fact is…",
        ["true and clearly explained", "made up for laughs only", "secret forever", "only a shrug"],
        "true and clearly explained"),
     mc("w32h2", "Three facts might come from…",
        ["US and Texas learning this year", "only game lore", "only random numbers", "empty boasts"],
        "US and Texas learning this year"),
     mc("w32h3", "A docent-style teacher should…",
        ["speak clearly and welcome questions", "mock listeners", "whisper unkindly", "hide all maps"],
        "speak clearly and welcome questions"),
     tf("w32h4", "True or False: Naming a source or lesson week can strengthen a fact share."),
     mc("w32h5", "Texas pride at museum night means…",
        ["thankful love of home with humility", "hating all other places", "worshiping the flag as God", "skipping truth"],
        "thankful love of home with humility"),
     mc("w32h6", "Why teach facts aloud?",
        ["to remember and bless listeners", "to erase history", "to avoid virtues", "to ban reading"],
        "to remember and bless listeners")],
    "museum_night_badge", 10)
add_item("museum_night_badge", "Museum Night Badge", "A badge for teaching three history facts aloud.", "accessory", "#9b2226", "w32-history-museum")

add_q(
    "w32-raid-review", "Raid Review: Steward Science Fair", 32, 5, "math",
    "Friday Raid — Week 32 Mixed Review",
    "\"Prove graphs, presentations, fair speaking, museum facts, Matthew 5:16.\"",
    [dlg(HS, "Week 32 proving. Mastery ≥80%."),
     dlg(HS, "Let light shine with honest data and kind words.")],
    [fb("w32r1", "If one star=3 and 4 stars, total?", "12"), fb("w32r2", "Bar 7 vs bar 3: difference?", "4"),
     mc("w32r3", "Thank-you notes should…",
        ["name the help and say thanks", "insult helpers", "be blank", "demand gifts"],
        "name the help and say thanks"),
     mc("w32r4", "Science fair conclusions here should…",
        ["honor the Creator", "deny design by rule", "worship weather", "hide results"],
        "honor the Creator"),
     mc("w32r5", "Museum night asks for…",
        ["three clear history facts", "zero facts", "only jokes", "only fractions"],
        "three clear history facts"),
     mc("w32r6", "Matthew 5:16: shine so others…",
        ["glorify the Father", "worship you", "hate good works", "hide light"],
        "glorify the Father"),
     tf("w32r7", "True or False: Graph labels help readers."),
     fb("w32r8", "2×8 then +5 =", "21")],
    "fair_cloak", 30)
add_item("fair_cloak", "Fair Cloak", "Cloak earned at the Steward Science Fair review.", "cape", "#2d6a4f", "w32-raid-review")

# ========== WEEK 33 — Citizenship Crown ==========
add_q(
    "w33-bible-kindness", "Honor One Another", 33, 1, "bible",
    "Bible — Romans 12:10 & Kindness",
    "\"Love one another with brotherly affection. Outdo one another in showing honor.\"",
    [dlg(SB, "Romans 12:10: kindly love and honor others — citizenship begins at home."),
     dlg(SB, "Virtue: Kindness. Crowns of citizenship are worn with humble honor.")],
    [mc("w33b1", "Romans 12:10 teaches…",
        ["love and honor toward one another", "hatred of neighbors", "pride as the highest good", "ignoring family"],
        "love and honor toward one another"),
     mc("w33b2", "Kindness looks like…",
        ["helpful, gentle words and deeds", "cruel jokes", "shoving to be first", "refusing courtesy"],
        "helpful, gentle words and deeds"),
     tf("w33b3", "True or False: Honoring others can include listening and fair turns."),
     mc("w33b4", "Citizens who honor others help…",
        ["peace in home and community", "chaos on purpose", "cruelty win", "erase manners"],
        "peace in home and community"),
     mc("w33b5", "Who wrote Romans?", ["Paul", "Houston", "a bar graph", "a soft c rule"], "Paul")],
    "kindness_crownlet", 10)
add_item("kindness_crownlet", "Kindness Crownlet", "A small crownlet for Romans 12:10 and honor.", "head", "#c9b037", "w33-bible-kindness")

add_q(
    "w33-math-money-time", "Money & Time Mastery", 33, 2, "math",
    "Math — Make Change; Elapsed Time Mastery",
    "\"Count change carefully; find elapsed time on clocks.\"",
    [dlg(MB, "Money: make change from a dollar or more. Time: elapsed time between start and end."),
     dlg(MB, "Kindness: honest change — never short a neighbor.")],
    [fb("w33m1", "Item costs 35¢. Pay $1.00. Change in cents?", "65"),
     fb("w33m2", "Item costs 70¢. Pay $1.00. Change in cents?", "30"),
     fb("w33m3", "From 3:00 to 3:25 is ____ minutes", "25"),
     fb("w33m4", "From 2:10 to 2:45 is ____ minutes", "35"),
     fb("w33m5", "4 quarters = ____ cents", "100"),
     mc("w33m6", "Elapsed time means…",
        ["how much time passed between two clock times", "only coin names", "only perimeter", "only spelling"],
        "how much time passed between two clock times"),
     fb("w33m7", "A book is $3 and a pencil $1. Total?", "4"),
     tf("w33m8", "True or False: Counting up from the price to the amount paid can help make change.")],
    "change_purse", 12)
add_item("change_purse", "Change Purse", "A purse token for money and elapsed-time mastery.", "belt", "#d4a017", "w33-math-money-time")

add_q(
    "w33-la-passage", "Long Passage Celebration", 33, 3, "la",
    "LA — Long Passage Comprehension",
    "\"Read a longer passage; prove understanding with clear answers.\"",
    [dlg(MS, "Celebration reading: main idea, details, vocabulary in context, inference with evidence."),
     dlg(MS, "Kindness to the author: read carefully before judging.")],
    [mc("w33l1", "Main idea is…",
        ["what the passage is mostly about", "a random detail only", "only the last comma", "the cape color"],
        "what the passage is mostly about"),
     mc("w33l2", "Supporting details…",
        ["explain or prove the main idea", "erase the main idea", "are never useful", "only list jokes"],
        "explain or prove the main idea"),
     mc("w33l3", "Context clues help you…",
        ["figure out a hard word from nearby text", "skip reading", "guess with no text", "ban dictionaries forever"],
        "figure out a hard word from nearby text"),
     tf("w33l4", "True or False: Good answers often point back to words in the passage."),
     mc("w33l5", "Inference means…",
        ["a careful conclusion using text clues", "a wild guess with no clues", "copying unrelated ads", "ignoring the story"],
        "a careful conclusion using text clues"),
     mc("w33l6", "Celebrating reading growth means…",
        ["noticing harder passages you can now understand", "pretending you never struggled", "mocking beginners", "quitting books"],
        "noticing harder passages you can now understand")],
    "passage_bookmark", 10)
add_item("passage_bookmark", "Passage Bookmark", "A bookmark for long-passage comprehension celebration.", "accessory", "#3a6ea5", "w33-la-passage")

add_q(
    "w33-science-scavenger", "Nature Journal Scavenger", 33, 4, "science",
    "Science — Complete Nature Journal; Outdoor Scavenger Hunt",
    "\"Finish journal pages; hunt outdoors for ordered wonders.\"",
    [dlg(SC, "Complete the nature journal. Outdoor scavenger: leaf shapes, bird signs, clouds, rocks — observe without harming."),
     dlg(SC, "Kindness to creation: look, learn, leave living things unharmed.")],
    [mc("w33s1", "A finished nature journal shows…",
        ["dated observations across the year", "blank pages only", "only doodles", "no outdoor notes"],
        "dated observations across the year"),
     mc("w33s2", "On a scavenger hunt you should…",
        ["observe carefully and respect living things", "harm nests for fun", "litter trails", "pick rare plants without care"],
        "observe carefully and respect living things"),
     mc("w33s3", "Cloud watching can teach…",
        ["weather clues God built into creation", "fortune-telling fate", "skipping science", "worship of clouds"],
        "weather clues God built into creation"),
     tf("w33s4", "True or False: Stewardship includes leaving habitats better than you found them when possible."),
     mc("w33s5", "Journal sketches help by…",
        ["recording shapes and details words might miss", "replacing all honesty", "banning labels", "hiding dates"],
        "recording shapes and details words might miss"),
     mc("w33s6", "Outdoor learning pairs well with…",
        ["thankfulness for creation", "cruelty to creatures", "chaos litter", "ignoring safety"],
        "thankfulness for creation")],
    "scavenger_satchel", 10)
add_item("scavenger_satchel", "Scavenger Satchel", "A satchel for nature-journal scavenger hunts.", "accessory", "#2d6a4f", "w33-science-scavenger")

add_q(
    "w33-history-citizenship", "Citizenship Crown", 33, 5, "history",
    "History — Rights, Responsibilities, Flag & Pledge",
    "\"Know rights with responsibilities; practice flag respect and pledge meaning.\"",
    [dlg(CK, "Citizens have rights and duties. Flag etiquette shows respect. The pledge is a promise of loyalty under God — understood, not mumbled."),
     dlg(CK, "Kindness and honor make liberty livable.")],
    [mc("w33h1", "Rights and responsibilities go…",
        ["together in good citizenship", "never together", "only with games", "only with fractions"],
        "together in good citizenship"),
     mc("w33h2", "Flag etiquette includes…",
        ["respectful handling and posture", "dragging the flag on purpose", "using it as a rag for jokes", "ignoring it always"],
        "respectful handling and posture"),
     mc("w33h3", "The Pledge of Allegiance is…",
        ["a promise of loyalty to the nation under God", "a math formula", "a Texas river name", "a luck charm"],
        "a promise of loyalty to the nation under God"),
     tf("w33h4", "True or False: Understanding words in the pledge matters more than racing through them."),
     mc("w33h5", "A responsibility example is…",
        ["obeying just laws and respecting others", "never helping neighbors", "littering freely", "mocking the flag"],
        "obeying just laws and respecting others"),
     mc("w33h6", "Respectful patriotism means…",
        ["love of country with humility before God", "hating all other nations", "worshiping the nation as God", "skipping history"],
        "love of country with humility before God")],
    "citizenship_crown", 12)
add_item("citizenship_crown", "Citizenship Crown", "A crown token for rights, duties, flag, and pledge.", "head", "#9b2226", "w33-history-citizenship")

add_q(
    "w33-raid-review", "Raid Review: Citizenship Crown", 33, 5, "math",
    "Friday Raid — Week 33 Mixed Review",
    "\"Prove money, time, long reading, scavenger stewardship, citizenship, kindness.\"",
    [dlg(HS, "Week 33 proving. Mastery ≥80%."),
     dlg(HS, "Honest change, clear reading, honored flag, kind hearts.")],
    [fb("w33r1", "Pay $1 for a 40¢ item. Change in cents?", "60"),
     fb("w33r2", "From 1:00 to 1:30 is ____ minutes", "30"),
     mc("w33r3", "Main idea is…",
        ["what the passage is mostly about", "a random comma", "only the title font", "empty boasts"],
        "what the passage is mostly about"),
     mc("w33r4", "Nature scavenger hunts should…",
        ["respect living things", "harm nests", "litter", "skip observation"],
        "respect living things"),
     mc("w33r5", "The pledge is…",
        ["a loyalty promise under God", "a fraction", "a planet", "a soft c rule"],
        "a loyalty promise under God"),
     mc("w33r6", "Romans 12:10 calls for…",
        ["love and honor", "cruelty", "pride as lord", "ignoring others"],
        "love and honor"),
     tf("w33r7", "True or False: Citizens have both rights and responsibilities."),
     fb("w33r8", "3 quarters = ____ cents", "75")],
    "citizenship_cloak", 30)
add_item("citizenship_cloak", "Citizenship Cloak", "Cloak earned at the Citizenship Crown review.", "cape", "#9b2226", "w33-raid-review")

# ========== WEEK 34 — Remediation Roads ==========
add_q(
    "w34-bible-perseverance", "Memory Paths & Perseverance", 34, 1, "bible",
    "Bible — Year Memory Verse Review & Perseverance",
    "\"Review the year's verses; keep walking when review feels long.\"",
    [dlg(SB, "Sample review: Genesis 1:1, fruit of the Spirit, Matthew 5:16, Psalm 100, Romans 12:10, and more from the year."),
     dlg(SB, "Virtue: Perseverance — clinics are roads, not dead ends.")],
    [mc("w34b1", "Perseverance means…",
        ["keeping on with courage when work is hard", "quitting at the first mistake", "mocking weak skills", "skipping review"],
        "keeping on with courage when work is hard"),
     mc("w34b2", "Genesis 1:1 begins…",
        ["In the beginning, God created…", "In the ending, chaos ruled…", "Texas became a state…", "2+2=4 only"],
        "In the beginning, God created…"),
     mc("w34b3", "Fruit of the Spirit includes…",
        ["love, joy, peace, patience, kindness…", "greed and spite only", "luck charms", "empty boasts"],
        "love, joy, peace, patience, kindness…"),
     tf("w34b4", "True or False: Reviewing memory verses helps them stay in the heart."),
     mc("w34b5", "Matthew 5:16 is about…",
        ["letting light shine to glorify the Father", "hiding good works forever", "worshiping lamps", "skipping kindness"],
        "letting light shine to glorify the Father"),
     mc("w34b6", "Clinics this week honor…",
        ["growth over pretending perfection", "shame as the goal", "hiding Needs Help lists", "never practicing"],
        "growth over pretending perfection")],
    "perseverance_path_band", 10)
add_item("perseverance_path_band", "Perseverance Path Band", "A band for memory review and clinic perseverance.", "accessory", "#c9b037", "w34-bible-perseverance")

add_q(
    "w34-math-clinic", "Math Weak-Skill Clinic", 34, 2, "math",
    "Math — Personalized Weak-Skill Clinic",
    "\"Use the Needs Help list; mill the thin spots until stronger.\"",
    [dlg(MB, "Parents: pick weak skills from the dashboard. Apprentices: practice with patience — facts, fractions, measure, multi-step, time/money."),
     dlg(MB, "Perseverance turns roads of remediation into glory paths.")],
    [fb("w34m1", "9 × 7 =", "63"), fb("w34m2", "81 ÷ 9 =", "9"), fb("w34m3", "2/9 + 5/9 =", "7/9"),
     fb("w34m4", "Perimeter of square side 8?", "32"), fb("w34m5", "Area of 7×3?", "21"),
     fb("w34m6", "From 4:00 to 4:40 is ____ minutes", "40"), fb("w34m7", "Pay $1 for 55¢. Change in cents?", "45"),
     fb("w34m8", "3 feet = ____ inches", "36"),
     tf("w34m9", "True or False: Practicing weak skills on purpose is wise."),
     mc("w34m10", "A clinic goal is…",
        ["strengthen thin spots with steady practice", "shame the learner", "skip hard topics forever", "only play without review"],
        "strengthen thin spots with steady practice")],
    "clinic_chalk", 12)
add_item("clinic_chalk", "Clinic Chalk", "Chalk for personalized math weak-skill clinics.", "belt", "#d4a017", "w34-math-clinic")

add_q(
    "w34-la-clinic", "Language Clinic Roads", 34, 3, "la",
    "LA — Grammar, Spelling, Fluency Clinics",
    "\"Polish thin spots: sentences, spelling patterns, smooth reading.\"",
    [dlg(MS, "Clinic menu: fragments vs sentences, punctuation, spelling patterns, oral fluency re-reads."),
     dlg(MS, "Persevere kindly — mistakes are teachers.")],
    [mc("w34l1", "A fragment is…",
        ["an incomplete sentence piece", "a full sentence with subject and verb", "always a poem", "a Texas river"],
        "an incomplete sentence piece"),
     mc("w34l2", "Fluency practice often uses…",
        ["re-reading familiar text smoothly", "never reading aloud", "only shouting", "skipping punctuation"],
        "re-reading familiar text smoothly"),
     mc("w34l3", "Spelling clinics may target…",
        ["patterns like tion/sion or vowel teams", "only cape dyes", "only glitter", "empty boasts"],
        "patterns like tion/sion or vowel teams"),
     tf("w34l4", "True or False: Editing a short paragraph can be a clinic task."),
     mc("w34l5", "Capital letters belong at…",
        ["starts of sentences and proper names", "every single letter always", "never", "only on maps"],
        "starts of sentences and proper names"),
     mc("w34l6", "A kind clinic attitude is…",
        ["try again with courage", "mock yourself harshly forever", "quit writing", "hide all errors without learning"],
        "try again with courage")],
    "language_clinic_slate", 10)
add_item("language_clinic_slate", "Language Clinic Slate", "A slate for grammar, spelling, and fluency clinics.", "accessory", "#3a6ea5", "w34-la-clinic")

add_q(
    "w34-science-catchup", "Catch-Up Labs & Walks", 34, 4, "science",
    "Science — Catch-Up Labs or Extra Nature Walks",
    "\"Finish unfinished labs; walk and wonder; fill journal gaps.\"",
    [dlg(SC, "Catch up: unfinished experiments, moon charts, habitat notes, or an extra stewardship walk."),
     dlg(SC, "Perseverance outdoors: one more careful page.")],
    [mc("w34s1", "Catch-up science might include…",
        ["finishing a lab or adding journal pages", "erasing the whole year", "skipping observation", "harming habitats"],
        "finishing a lab or adding journal pages"),
     mc("w34s2", "A nature walk for catch-up should…",
        ["observe and record with stewardship", "litter", "rush without looking", "worship creatures"],
        "observe and record with stewardship"),
     mc("w34s3", "Moon charts track…",
        ["changing shapes over nights", "tax rates", "only spelling", "PIN codes"],
        "changing shapes over nights"),
     tf("w34s4", "True or False: It is good to finish incomplete project notes before festival."),
     mc("w34s5", "Weather tools include…",
        ["thermometer and rain gauge", "luck charm only", "only yardsticks as weather", "only cloaks"],
        "thermometer and rain gauge"),
     mc("w34s6", "Plant parts include…",
        ["roots, stems, leaves, flowers", "only capes", "only bars on graphs", "only pledges"],
        "roots, stems, leaves, flowers")],
    "catchup_walk_token", 10)
add_item("catchup_walk_token", "Catch-Up Walk Token", "A token for catch-up labs and nature walks.", "accessory", "#2d6a4f", "w34-science-catchup")

add_q(
    "w34-history-catchup", "Timeline Gaps & Symbols Quiz", 34, 5, "history",
    "History — Timeline Gaps; Texas Symbols Quiz",
    "\"Fill timeline holes; quiz Texas symbols with pride and accuracy.\"",
    [dlg(CK, "Catch up missing timeline cards. Quiz: bluebonnet, mockingbird, pecan, flag meanings, capital."),
     dlg(CK, "Persevere until the story hangs together.")],
    [mc("w34h1", "Texas state flower?",
        ["bluebonnet", "rose of England only", "cactus candy only", "pine of Maine only"], "bluebonnet"),
     mc("w34h2", "Texas state bird?",
        ["mockingbird", "eagle of Rome only", "penguin", "ostrich"], "mockingbird"),
     mc("w34h3", "Texas state tree often named…",
        ["pecan", "redwood only", "palm of Florida only", "maple of Canada only"], "pecan"),
     tf("w34h4", "True or False: Filling timeline gaps helps the year's story make sense."),
     mc("w34h5", "Texas capital?", ["Austin", "Boston", "Santa Fe only", "New York City"], "Austin"),
     mc("w34h6", "A timeline gap clinic is for…",
        ["reviewing missing events with care", "erasing Texas", "banning maps", "skipping symbols"],
        "reviewing missing events with care")],
    "symbols_quiz_card", 10)
add_item("symbols_quiz_card", "Symbols Quiz Card", "A card for Texas symbols and timeline gap review.", "accessory", "#9b2226", "w34-history-catchup")

add_q(
    "w34-raid-review", "Raid Review: Remediation Roads", 34, 5, "math",
    "Friday Raid — Week 34 Mixed Review",
    "\"Prove clinic skills across subjects; perseverance on the path.\"",
    [dlg(HS, "Week 34 proving. Mastery ≥80%."),
     dlg(HS, "Roads of remediation lead toward festival light.")],
    [fb("w34r1", "8 × 9 =", "72"), fb("w34r2", "1/5 of 20 =", "4"), fb("w34r3", "Area of 6×6?", "36"),
     mc("w34r4", "A sentence fragment is…", ["incomplete", "always a full sentence", "a river", "a coin"], "incomplete"),
     mc("w34r5", "Texas state flower?", ["bluebonnet", "tulip only", "oak leaf only", "cactus candy only"], "bluebonnet"),
     mc("w34r6", "Perseverance means…",
        ["keeping on when work is hard", "quitting early", "mocking weakness", "hiding Needs Help forever"],
        "keeping on when work is hard"),
     tf("w34r7", "True or False: Memory verse review strengthens the heart."),
     fb("w34r8", "Pay $1 for 25¢. Change in cents?", "75")],
    "remediation_cloak", 30)
add_item("remediation_cloak", "Remediation Cloak", "Cloak earned at the Remediation Roads review.", "cape", "#7f5539", "w34-raid-review")

# ========== WEEK 35 — Raid Review Supreme ==========
add_q(
    "w35-bible-fruit-full", "Fruit Full Recite", 35, 1, "bible",
    "Bible — Fruit of the Spirit Full Recite & Faithfulness",
    "\"Recite Galatians 5:22–23 fully; crown the year with faithfulness.\"",
    [dlg(SB, "Full recite: love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, self-control."),
     dlg(SB, "Virtue: Faithfulness — finishing the year as a steady steward.")],
    [mc("w35b1", "Faithfulness means…",
        ["steady loyalty and kept promises", "quitting when bored", "lying to look good", "hiding duties"],
        "steady loyalty and kept promises"),
     mc("w35b2", "How many fruit qualities are commonly listed in Galatians 5:22–23?",
        ["nine", "two", "one hundred", "zero"], "nine"),
     mc("w35b3", "Which set is part of the fruit?",
        ["gentleness and self-control", "cruelty and greed", "luck and chaos", "spite and pride"],
        "gentleness and self-control"),
     tf("w35b4", "True or False: Faithfulness includes finishing review work honestly."),
     mc("w35b5", "The fruit is grown by…",
        ["the Holy Spirit in believers", "cape shopping alone", "empty boasts alone", "random chance charms"],
        "the Holy Spirit in believers"),
     mc("w35b6", "Reciting Scripture helps us…",
        ["hide God's words in our hearts", "replace kindness", "mock memory", "skip virtues"],
        "hide God's words in our hearts")],
    "faithfulness_seal", 12)
add_item("faithfulness_seal", "Faithfulness Seal", "A seal for full fruit recite and year faithfulness.", "accessory", "#c9b037", "w35-bible-fruit-full")

add_q(
    "w35-math-year", "Year Math Assessment", 35, 2, "math",
    "Math — Year Traditional Skills Assessment",
    "\"Prove the year's math: facts, fractions, measure, geometry, time, money, graphs, multi-step.\"",
    [dlg(MB, "Year assessment — traditional skills. Show your work with calm faithfulness."),
     dlg(MB, "Parents may note strengths and Needs Help for the progress report.")],
    [fb("w35m1", "12 × 11 =", "132"), fb("w35m2", "144 ÷ 12 =", "12"), fb("w35m3", "3/10 + 4/10 =", "7/10"),
     fb("w35m4", "1/4 of 16 =", "4"), fb("w35m5", "Perimeter of 9×4 rectangle?", "26"), fb("w35m6", "Area of 9×4?", "36"),
     fb("w35m7", "36 inches = ____ yards", "1"), fb("w35m8", "From 5:15 to 5:55 is ____ minutes", "40"),
     fb("w35m9", "If one symbol=5 and 3 symbols, total?", "15"), fb("w35m10", "2 crates of 9, then −6 =", "12"),
     tf("w35m11", "True or False: Checking work is part of faithfulness in math.")],
    "year_math_seal", 15)
add_item("year_math_seal", "Year Math Seal", "A seal for the year math assessment.", "accessory", "#d4a017", "w35-math-year")

add_q(
    "w35-la-year", "Year Language Assessment", 35, 3, "la",
    "LA — Year Reading, Writing Sample, Grammar",
    "\"Assess reading sense, a short writing sample, and grammar polish.\"",
    [dlg(MS, "Year LA: comprehension check, short writing sample (paragraph), grammar/mechanics."),
     dlg(MS, "Faithfulness: best effort, not borrowed answers.")],
    [mc("w35l1", "A paragraph usually groups…",
        ["sentences about one main idea", "random unrelated shouts", "only numbers", "only maps"],
        "sentences about one main idea"),
     mc("w35l2", "Grammar assessment may check…",
        ["sentences, parts of speech, punctuation", "only cape color", "only glitter", "empty boasts"],
        "sentences, parts of speech, punctuation"),
     mc("w35l3", "A writing sample should…",
        ["answer the prompt clearly with complete sentences", "be blank", "be only scribbles with no words", "copy without thinking"],
        "answer the prompt clearly with complete sentences"),
     tf("w35l4", "True or False: Reading assessments look for main idea and details."),
     mc("w35l5", "Revision improves…",
        ["clarity and organization", "only ink blots", "chaos", "unrelated jokes"],
        "clarity and organization"),
     mc("w35l6", "Quotation marks often mark…",
        ["spoken words or titles of short works", "only yards", "only ounces", "only planets"],
        "spoken words or titles of short works"),
     mc("w35l7", "Faithful writers…",
        ["use their own words and honest effort", "always cheat", "never edit", "insult readers"],
        "use their own words and honest effort")],
    "year_la_seal", 12)
add_item("year_la_seal", "Year LA Seal", "A seal for the year language arts assessment.", "accessory", "#3a6ea5", "w35-la-year")

add_q(
    "w35-science-conference", "Science Oral Conference", 35, 4, "science",
    "Science — Year Oral Science Conference",
    "\"Speak what you learned: creation order, habitats, weather, rocks, sky, stewardship.\"",
    [dlg(SC, "Oral conference: share highlights from the year's science with creation-honoring framing."),
     dlg(SC, "Faithfulness: true memories, not invented marvels.")],
    [mc("w35s1", "Creation week study reminds us…",
        ["God made the world with purpose", "the world made itself as god", "science bans wonder", "skies are luck charms"],
        "God made the world with purpose"),
     mc("w35s2", "Habitats are…",
        ["homes where living things find what they need", "only video stages", "only fractions", "PIN codes"],
        "homes where living things find what they need"),
     mc("w35s3", "The water cycle includes…",
        ["evaporation, condensation, precipitation ideas", "only voting", "only spelling", "only capes"],
        "evaporation, condensation, precipitation ideas"),
     tf("w35s4", "True or False: Solar system study here thanks the Creator and rejects star fortune-telling."),
     mc("w35s5", "Stewardship means…",
        ["caring for land and creatures as God's trust", "wasting freely", "Earth goddess worship", "ignoring trash"],
        "caring for land and creatures as God's trust"),
     mc("w35s6", "Rocks and soil study can show…",
        ["variety and usefulness in creation", "nothing to learn", "only shiny rocks as the whole lesson", "ban outdoor walks"],
        "variety and usefulness in creation"),
     mc("w35s7", "A science conference answer should be…",
        ["clear and honest", "false on purpose", "rude", "empty"],
        "clear and honest")],
    "science_conference_pin", 12)
add_item("science_conference_pin", "Science Conference Pin", "A pin for the year oral science conference.", "accessory", "#2d6a4f", "w35-science-conference")

add_q(
    "w35-history-conference", "History Year Conference", 35, 5, "history",
    "History — US + Texas + Bible Touchpoints Conference",
    "\"Oral conference: US story, Texas story, and humble Bible touchpoints.\"",
    [dlg(CK, "Conference: colonies→Revolution→Constitution; Texas path to statehood; virtues and Scripture ties without forcing every date."),
     dlg(CK, "Faithfulness: age-right honesty about hardship and hope.")],
    [mc("w35h1", "US Independence era centers on…",
        ["1776 Declaration ideals", "1845 only", "moon phases", "soft c only"],
        "1776 Declaration ideals"),
     mc("w35h2", "Texas statehood year?", ["1845", "1492", "2000", "Day 1 of Creation only"], "1845"),
     mc("w35h3", "The Constitution provides…",
        ["a framework of laws and rights", "a recipe for bread only", "a times table only", "a cape dye chart only"],
        "a framework of laws and rights"),
     tf("w35h4", "True or False: Texas was a republic before it became a state."),
     mc("w35h5", "Bible touchpoints in history class mean…",
        ["noticing faith and virtue themes with care", "forcing every event into a verse roughly", "banning history", "worshiping nations as God"],
        "noticing faith and virtue themes with care"),
     mc("w35h6", "San Jacinto is tied to…",
        ["Texas Independence / Republic beginnings", "inventing graphs", "writing Romans", "building rain gauges only"],
        "Texas Independence / Republic beginnings"),
     mc("w35h7", "A faithful conference voice is…",
        ["clear, respectful, and truthful", "boastful and false", "silent from spite", "unkind to listeners"],
        "clear, respectful, and truthful")],
    "history_conference_pin", 12)
add_item("history_conference_pin", "History Conference Pin", "A pin for the year US/Texas history conference.", "accessory", "#9b2226", "w35-history-conference")

add_q(
    "w35-raid-supreme", "Raid Review Supreme", 35, 5, "math",
    "Friday Raid — Year Review Supreme",
    "\"Supreme proving across the year's lights — then rest before festival.\"",
    [dlg(HS, "Raid Review Supreme. Mastery ≥80%. Parents: draft end-of-year progress notes."),
     dlg(HS, "Faithfulness finishes well; festival joy comes next.")],
    [fb("w35r1", "7 × 9 =", "63"), fb("w35r2", "2/8 + 3/8 =", "5/8"), fb("w35r3", "Area of 5×5?", "25"),
     fb("w35r4", "3 feet = ____ yard(s)", "1"),
     mc("w35r5", "Fruit of the Spirit includes…",
        ["faithfulness and self-control", "cruelty", "chaos worship", "greed as fruit"],
        "faithfulness and self-control"),
     mc("w35r6", "Texas capital?", ["Austin", "Neptune", "London", "Boston only"], "Austin"),
     mc("w35r7", "Stewardship is…",
        ["caring for what God entrusted", "wasting creation", "idolatry of nature", "ignoring neighbors"],
        "caring for what God entrusted"),
     mc("w35r8", "A paragraph holds…",
        ["sentences about one main idea", "only jokes", "no words", "only ounces"],
        "sentences about one main idea"),
     tf("w35r9", "True or False: Year assessments help families see growth."),
     fb("w35r10", "Pay $1 for 80¢. Change in cents?", "20")],
    "supreme_cloak", 40)
add_item("supreme_cloak", "Supreme Cloak", "Cloak earned at Raid Review Supreme.", "cape", "#c9a227", "w35-raid-supreme")

# ========== WEEK 36 — Festival of Lumens ==========
add_q(
    "w36-bible-love", "Festival Thanksgiving & Love", 36, 1, "bible",
    "Bible — Thanksgiving Worship & Love",
    "\"Share character growth; thank the High King; walk in love.\"",
    [dlg(SB, "Festival worship: thank God for the year's light. Virtue crown: Love — the greatest fruit."),
     dlg(SB, "Tell one story of growth: patience learned, kindness shown, truth told.")],
    [mc("w36b1", "Love as a Christian virtue means…",
        ["seeking others' good in action", "using people for praise", "never forgiving", "hiding thanks"],
        "seeking others' good in action"),
     mc("w36b2", "Thanksgiving worship focuses on…",
        ["gratitude to God for gifts and growth", "boasting only", "grumbling as praise", "ignoring helpers"],
        "gratitude to God for gifts and growth"),
     mc("w36b3", "Character growth stories should be…",
        ["honest and humble", "false brags", "unkind comparisons", "secret from spite only"],
        "honest and humble"),
     tf("w36b4", "True or False: Love fulfills much of what the fruit of the Spirit looks like toward neighbors."),
     mc("w36b5", "Festival of Lumens celebrates…",
        ["a year of learning light under the High King", "chaos as lord", "quitting virtue", "erasing Scripture"],
        "a year of learning light under the High King"),
     mc("w36b6", "Which fruit is listed first in Galatians 5:22?",
        ["love", "spite", "greed", "chaos"], "love")],
    "love_lumen_pendant", 12)
add_item("love_lumen_pendant", "Love Lumen Pendant", "A pendant for festival thanksgiving and love.", "accessory", "#c9b037", "w36-bible-love")

add_q(
    "w36-math-feast", "Math Games Feast", 36, 2, "math",
    "Math — Celebration Games; Fact Mastery Party",
    "\"Play math games; celebrate × fluency and year skills with joy.\"",
    [dlg(MB, "Feast games: fact races with kindness, measure scavenger, fraction pizza share, graph toss questions."),
     dlg(MB, "Love: cheer classmates; no unkind rivalry.")],
    [fb("w36m1", "6 × 8 =", "48"), fb("w36m2", "9 × 9 =", "81"), fb("w36m3", "100 ÷ 10 =", "10"),
     fb("w36m4", "1/2 of 14 =", "7"), fb("w36m5", "Perimeter of square side 10?", "40"),
     mc("w36m6", "Festival math should feel like…",
        ["joyful practice and celebration", "shame punishment", "cruel rivalry only", "skipping all facts"],
        "joyful practice and celebration"),
     fb("w36m7", "2/6 + 3/6 =", "5/6"),
     tf("w36m8", "True or False: Cheering others' progress shows love."),
     fb("w36m9", "4 quarts = ____ gallon(s)", "1")],
    "feast_game_die", 12)
add_item("feast_game_die", "Feast Game Die", "A game die for the math celebration feast.", "belt", "#d4a017", "w36-math-feast")

add_q(
    "w36-la-author", "Author Party", 36, 3, "la",
    "LA — Author Party; Read Favorite Pieces",
    "\"Host an author party; read favorite pieces to celebrating listeners.\"",
    [dlg(MS, "Author party: share a favorite narrative, informational piece, poem, or booklet page."),
     dlg(MS, "Love listens well when others read.")],
    [mc("w36l1", "An author party is a time to…",
        ["share writing and encourage others", "mock every piece", "hide all writing", "ban reading aloud"],
        "share writing and encourage others"),
     mc("w36l2", "Good audience manners include…",
        ["eyes on the reader and kind applause", "talking over the reader", "rude jokes mid-line", "leaving noisily to hurt feelings"],
        "eyes on the reader and kind applause"),
     mc("w36l3", "Choosing a favorite piece means…",
        ["picking work you are glad to share", "picking only to shame others", "never choosing", "burning drafts"],
        "picking work you are glad to share"),
     tf("w36l4", "True or False: Authors may thank people who helped them revise."),
     mc("w36l5", "Listening with love looks like…",
        ["attention and encouragement", "yawning insults", "phone distraction on purpose", "interrupting to boast"],
        "attention and encouragement"),
     mc("w36l6", "Festival writing memories help families…",
        ["see growth across the year", "erase the portfolio", "ban books", "skip celebration"],
        "see growth across the year")],
    "author_party_badge", 10)
add_item("author_party_badge", "Author Party Badge", "A badge for sharing favorite writing at festival.", "accessory", "#3a6ea5", "w36-la-author")

add_q(
    "w36-science-hike", "Creation Praise Hike", 36, 4, "science",
    "Science — Creation Praise Hike / Picnic",
    "\"Walk or picnic in creation; praise the Maker; review wonders.\"",
    [dlg(SC, "Praise hike or picnic: notice sky, plants, creatures; speak thanks aloud."),
     dlg(SC, "Love for the Creator overflows in careful delight — not litter.")],
    [mc("w36s1", "A creation praise hike is for…",
        ["thanking God while observing nature", "worshiping nature as God", "littering trails", "harming nests"],
        "thanking God while observing nature"),
     mc("w36s2", "Picnic stewardship includes…",
        ["packing out trash and respecting places", "leaving wrappers", "carving harmfully on living trees for fun", "chasing wildlife to exhaust them"],
        "packing out trash and respecting places"),
     mc("w36s3", "Speaking wonders aloud can…",
        ["teach younger siblings and honor God", "replace kindness", "ban science journals", "erase memory"],
        "teach younger siblings and honor God"),
     tf("w36s4", "True or False: Festival science can be joyful without being careless."),
     mc("w36s5", "Year science highlights might include…",
        ["habitats, weather, rocks, sky order, stewardship", "only empty boasts", "only PIN codes", "only cape dyes"],
        "habitats, weather, rocks, sky order, stewardship"),
     mc("w36s6", "Praise differs from nature worship because…",
        ["praise thanks the Creator; worship of creation is rejected", "they are identical", "praise bans observation", "science bans thanks"],
        "praise thanks the Creator; worship of creation is rejected")],
    "praise_hike_token", 10)
add_item("praise_hike_token", "Praise Hike Token", "A token for the creation praise hike or picnic.", "accessory", "#2d6a4f", "w36-science-hike")

add_q(
    "w36-history-gamenight", "History Game Night", 36, 5, "history",
    "History — Family Texas/US History Game Night",
    "\"Play timeline games, symbol quizzes, and map races with family joy.\"",
    [dlg(CK, "Game night: timeline relay, symbol match, map pin races — celebrate Texas and US learning."),
     dlg(CK, "Love: let younger players win kindness; truth still matters.")],
    [mc("w36h1", "History game night should…",
        ["review facts with joyful family play", "shame losers harshly", "ban Texas topics", "invent false dates for points"],
        "review facts with joyful family play"),
     mc("w36h2", "A timeline relay might order…",
        ["key US and Texas events", "only random colors", "only ounces", "only soft g words"],
        "key US and Texas events"),
     mc("w36h3", "Symbol match may include…",
        ["bluebonnet, flag meanings, capital", "only empty badges", "only fractions", "only moon gods"],
        "bluebonnet, flag meanings, capital"),
     tf("w36h4", "True or False: Kind rules make game night more loving."),
     mc("w36h5", "Texas pride at festival means…",
        ["thankful joy for home and heritage", "hatred of outsiders", "skipping truth", "worshiping the state as God"],
        "thankful joy for home and heritage"),
     mc("w36h6", "Map races practice…",
        ["finding cities, rivers, and regions quickly", "erasing maps", "banning geography", "only cape fashion"],
        "finding cities, rivers, and regions quickly")],
    "history_gamenight_cup", 10)
add_item("history_gamenight_cup", "History Game Night Cup", "A cup for family Texas/US history game night.", "accessory", "#9b2226", "w36-history-gamenight")

add_q(
    "w36-raid-feast", "Festival of Lumens Feast", 36, 5, "math",
    "Friday Raid — Campaign IV & Year Champion Feast",
    "\"Celebrate Light for the Realm — receive Campaign IV badge and year champion honors.\"",
    [dlg(HS, "Festival of Lumens! Master this feast (≥80%) to claim Campaign IV and year champion honors."),
     dlg(HS, "Parents: award certificates, archive the portfolio, rest in gratitude. The year's lamps are lit.")],
    [fb("w36r1", "8 × 8 =", "64"), fb("w36r2", "1/3 of 15 =", "5"), fb("w36r3", "Perimeter of square side 7?", "28"),
     fb("w36r4", "16 oz = ____ lb", "1"),
     mc("w36r5", "Campaign IV theme centers on…",
        ["consolidation, celebration, and shining light", "quitting virtue", "chaos worship", "erasing Texas"],
        "consolidation, celebration, and shining light"),
     mc("w36r6", "Fruit of the Spirit begins with…", ["love", "spite", "greed", "luck"], "love"),
     mc("w36r7", "Texas statehood?", ["1845", "1776 only", "1492", "2000"], "1845"),
     mc("w36r8", "A year champion finishes with…",
        ["faithfulness, gratitude, and love", "cruel pride only", "hidden plagiarism", "mocking beginners"],
        "faithfulness, gratitude, and love"),
     tf("w36r9", "True or False: The Festival of Lumens completes the 36-week content arc."),
     mc("w36r10", "Let your light shine so others…",
        ["glorify the Father", "worship you", "hate good works", "hide lamps"],
        "glorify the Father")],
    "campaign_iv_badge", 50, ["year_champion_cloak", "year_champion_certificate"])
add_item("campaign_iv_badge", "Campaign IV Badge", "The Light for the Realm campaign badge — mastery, projects, and celebration.", "accessory", "#c9a227", "w36-raid-feast")
add_item("year_champion_cloak", "Year Champion Cloak", "A feast cloak for completing the 36-week year arc.", "cape", "#c9b037", "w36-raid-feast")
add_item("year_champion_certificate", "Year Champion Certificate", "A certificate token for year completion — archive with the portfolio.", "accessory", "#f0e6d2", "w36-raid-feast")


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
    assert len(items) == 56, f"expected 56 items, got {len(items)}"

    for q in quests:
        for ch in q["challenges"]:
            assert ch.get("answer") not in (None, ""), (q["id"], ch["id"])
            if ch["type"] in ("multiple-choice", "true-false"):
                assert ch["answer"] in ch["options"], (q["id"], ch["id"], ch["answer"])

    qpath = ROOT / "quests.json"
    ipath = ROOT / "items.json"
    wpath = ROOT / "world.json"

    old_q = json.loads(qpath.read_text())
    old_q = [q for q in old_q if int(q.get("week", 1)) < 28]
    old_q.extend(quests)
    qpath.write_text(json.dumps(old_q, indent=2, ensure_ascii=False) + "\n")

    old_i = json.loads(ipath.read_text())
    for k in list(items.keys()):
        old_i.pop(k, None)
    old_i.update(items)
    ipath.write_text(json.dumps(old_i, indent=2, ensure_ascii=False) + "\n")

    world = json.loads(wpath.read_text())
    buckets = {
        "npc-builder": [q["id"] for q in quests if q["guild"] == "math"],
        "npc-scribe": [q["id"] for q in quests if q["guild"] == "la"],
        "npc-creation": [q["id"] for q in quests if q["guild"] == "science"],
        "npc-chronicle": [q["id"] for q in quests if q["guild"] == "history"],
        "npc-steward": [q["id"] for q in quests if q["guild"] == "bible"],
    }

    for npc in world["npcs"]:
        npc["quest_ids"] = [x for x in npc["quest_ids"] if week_num(x) < 28]
        npc["quest_ids"].extend(buckets.get(npc["id"], []))
        print(npc["id"], len(npc["quest_ids"]))

    wpath.write_text(json.dumps(world, indent=2, ensure_ascii=False) + "\n")
    print(f"OK: {len(old_q)} quests, {len(old_i)} items, weeks",
          sorted({int(q['week']) for q in old_q}))

if __name__ == "__main__":
    main()
