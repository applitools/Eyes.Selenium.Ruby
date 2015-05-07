class Applitools::Selenium::TestResults
  attr_accessor :is_new, :url
  attr_reader :steps, :matches, :mismatches, :missing, :exact_matches, :strict_matches,
              :content_matches, :layout_matches, :none_matches, :is_passed
  def initialize(steps=0, matches=0, mismatches=0, missing=0,
                 exact_matches=0, strict_matches=0, content_matches=0,
                 layout_matches=0, none_matches=0)
    @steps = steps
    @matches = matches
    @mismatches =  mismatches
    @missing =  missing
    @exact_matches =  exact_matches
    @strict_matches = strict_matches
    @content_matches =  content_matches
    @layout_matches =  layout_matches
    @none_matches =  none_matches
    @is_new = nil
    @url = nil
  end

  def is_passed
    !is_new && mismatches == 0 && missing ==0
  end

  def to_s
    is_new_str = ""
    unless is_new.nil?
      is_new_str = is_new ? "New test" : "Existing test"
    end
    "#{is_new_str} [ steps: #{steps}, matches: #{matches}, mismatches: #{mismatches}, missing: #{missing} ], URL: #{url}"
  end
end
