-- OmniRal

local SharedGlobalValues = {}

SharedGlobalValues.ScoreFinalizeTime = 10 -- How long it takes before the players current score run resets to zero
SharedGlobalValues.BonusPointsPerConsecutiveHit = 200 -- How many points you get when one NPC ragdolls into another

SharedGlobalValues.MultiplierGainPerHit = 0.5 -- How much the multiplier goes up when the players pushes an NPC
SharedGlobalValues.MultiplierGainPerConsecutiveHit = 0.25 -- How much the multiplier goes up when an NPC ragdolls into another

return SharedGlobalValues