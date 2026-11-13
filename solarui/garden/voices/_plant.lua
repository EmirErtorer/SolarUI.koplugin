-- The plain voice of a plant companion, used until the species has a voice
-- of its own (garden/voice.lua says how a voice is written).

return {
    moments = {
        greet = { "Good [morning|day]. I turned toward you when you came in.", "Welcome. The light is good today.",
            "Hello. I grew a little in the night." },
        idle = { "I am [growing|here], slowly. That is all I do.", "The soil is warm. I am content.",
            { t = "The rain is lovely. I am drinking.", when = { weather = "rain" } },
            { t = "Dark has come. I rest, and you may read.", when = { hour = "night" } },
            { t = "Cold, but I can wait for spring.", when = { season = "winter" } } },
        tap = { "Hello to you too.", "I felt that, a little.", "Gently, please. I am pleased." },
        read_today = { "{pages} pages today. I enjoyed them.", "You read today. I drank in every page." },
        nudge = { "No pages yet today. There is still time.", "Whenever you are ready, I will be here." },
        goal = { "You reached your goal today. Well read." },
        book_now = { "How is {book}? I would like to hear.", "{book} is waiting for you." },
        welcome_back = { "You are back. I kept growing.", "I missed you. Welcome home." },
        finished = { "You finished {last}. That is a good thing to have done." },
        level = { "We are closer now than we were. I am glad." },
        streak = { "{streak} days of reading in a row. I have kept count." },
        anniversary = { "{days} days since we met. Thank you for every one." },
        quote = { "You read this once: {quote}" },
    },
    beats = {},
}
