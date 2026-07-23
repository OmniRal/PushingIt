-- OmniRal

local SharedGlobalValues = {}

SharedGlobalValues.MaxLevel = 25

SharedGlobalValues.ChargeGain_Base = 1.4
SharedGlobalValues.ChargeGain_Subtract = 0.2

SharedGlobalValues.ScoreFinalizeTime = 3 -- How long it takes before the players current score run resets to zero
SharedGlobalValues.BonusPointsPerConsecutiveHit = 200 -- How many points you get when one NPC ragdolls into another

SharedGlobalValues.MultiplierGainPerHit = 0.5 -- How much the multiplier goes up when the players pushes an NPC
SharedGlobalValues.MultiplierGainPerConsecutiveHit = 0.25 -- How much the multiplier goes up when an NPC ragdolls into another

SharedGlobalValues.PushCooldown_Base = 2
SharedGlobalValues.PushCooldown_Subtract = 0.2

SharedGlobalValues.DodgeDuration = 0.5
SharedGlobalValues.DodgeCooldown_Base = 3
SharedGlobalValues.DodgeCooldown_Subtract = 0.3

return SharedGlobalValues