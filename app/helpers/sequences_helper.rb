module SequencesHelper
  def bleed_risk_style(sequence)
    bleed_risk = sequence.bleed_risk
    '-webkit-filter: sepia(%{bleed_risk}) saturate(3) hue-rotate(-50deg) drop-shadow(0 0 2px rgba(255,0,0,%{bleed_risk}));
    filter: sepia(%{bleed_risk}) saturate(3) hue-rotate(-50deg) drop-shadow(0 0 2px rgba(255,0,0,%{bleed_risk}));' %
      {:bleed_risk => bleed_risk}
  end
end
