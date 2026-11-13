-- The plain voice of an animal companion, used until the species has a voice
-- of its own (garden/voice.lua says how a voice is written).

return {
    moments = {
        greet = { "Good [morning|day|to see you]. I was hoping you would come.", "There you are. The garden has been quiet without you.",
            "Hello again. Shall we read something today?" },
        idle = { "I am [keeping you company|right here].", "This is a good place to sit, [here|next to your books].",
            { t = "The rain suits me. Stay in and read.", when = { weather = "rain" } },
            { t = "Night is coming. A page or two before bed?", when = { hour = "night" } },
            { t = "Snow on the garden. A fine day for a long chapter.", when = { weather = "snow" } } },
        tap = { "Hello to you too.", "That was kind.", "I like that.", "Again, if you like." },
        read_today = { "{pages} pages today. I listened to every one.", "You have read today. I noticed." },
        nudge = { "No pages yet today. There is still time.", "Whenever you are ready, I will be here." },
        goal = { "You reached your goal today. Well read." },
        book_now = { "How is {book}? I would like to hear.", "{book} is waiting for you." },
        welcome_back = { "You are back. I kept your place.", "I missed you. Welcome home." },
        finished = { "You finished {last}. That is a good thing to have done." },
        level = { "We are closer now than we were. I am glad." },
        streak = { "{streak} days of reading in a row. I have kept count." },
        anniversary = { "{days} days since we met. Thank you for every one." },
        quote = { "You read this once: {quote}" },
    },
    beats = {},
}
