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
        locked = { "I am glad you asked. Read a while longer, {pages} pages more and a few days, and I will come back to you.",
            "Not yet. Keep reading, {pages} pages more, and let the days pass. Then ask me again." },
        returned = { "You kept reading, and here I am. Thank you for waiting for me.", "I have been in the orchard, and I am ready to grow beside you again." },
    },
    beats = {},
}
