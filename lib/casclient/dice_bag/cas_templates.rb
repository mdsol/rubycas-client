require 'dice_bag'

class CasClientTemplate < DiceBag::AvailableTemplates
  def templates
    ['cas.yml.dice'].map do |template|
      File.join(File.dirname(__FILE__), template)
    end
  end
end
