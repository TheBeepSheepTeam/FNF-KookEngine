package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxStringUtil;
import AtlasChar;
import AtlasFontData.AtlasFont;
import AtlasFontData;
import AtlasFontData.Case;

@:forward
abstract DefaultText(AtlasText) from AtlasText to AtlasText
{
	inline public function new (x = 0.0, y = 0.0, text:String)
	{
		this = new AtlasText(x, y, text, Default);
	}
}

@:forward
abstract BoldText(AtlasText) from AtlasText to AtlasText
{
	inline public function new (x = 0.0, y = 0.0, text:String)
	{
		this = new AtlasText(x, y, text, Bold);
	}
}

/**
 * Alphabet.hx has a ton of bugs and does a bunch of stuff I don't need, fuck that class
 */
class AtlasText extends FlxTypedSpriteGroup<AtlasChar>
{
	static var fonts = new Map<AtlasFont, AtlasFontData>();
	static var casesAllowed = new Map<AtlasFont, Case>();
	public var text(default, set):String = "";
	
	var font:AtlasFontData;
	
	public var atlas(get, never):FlxAtlasFrames;
	inline function get_atlas() return font.atlas;
	public var caseAllowed(get, never):Case;
	inline function get_caseAllowed() return font.caseAllowed;
	public var maxHeight(get, never):Float;
	inline function get_maxHeight() return font.maxHeight;
	
	public function new (x = 0.0, y = 0.0, text:String, fontName:AtlasFont = Default)
	{
		if (!fonts.exists(fontName))
			fonts[fontName] = new AtlasFontData(fontName);
		font = fonts[fontName];
		
		super(x, y);
		
		this.text = text;
	}
	
	function set_text(value:String)
	{
		if (value == null)
			value = "";
		
		var caseValue = restrictCase(value);
		var caseText = restrictCase(this.text);
		
		this.text = value;
		if (caseText == caseValue)
			return value; // cancel redraw
		
		if (caseValue.indexOf(caseText) == 0)
		{
			// new text is just old text with additions at the end, append the difference
			appendTextCased(caseValue.substr(caseText.length));
			return this.text;
		}
		
		value = caseValue;
		
		group.kill();
		
		if (value == "")
			return this.text;
		
		appendTextCased(caseValue);
		return this.text;
	}
	
	/**
	 * Adds new characters, without needing to redraw the previous characters
	 * @param text The text to add.
	 * @throws String if `text` is null.
	 */
	public function appendText(text:String)
	{
		if (text == null)
			throw "cannot append null";
		
		if (text == "")
			return;
		
		this.text = this.text + text;
	}
	
	/**
	 * Converts all characters to fit the font's `allowedCase`.
	 * @param text 
	 */
	function restrictCase(text:String)
	{
		return switch(caseAllowed)
		{
			case Both: text;
			case Upper: text.toUpperCase();
			case Lower: text.toLowerCase();
		}
	}
	
	/**
	 * Adds new text on top of the existing text. Helper for other methods; DOESN'T CHANGE `this.text`.
	 * @param text The text to add, assumed to match the font's `caseAllowed`.
	 */
	function appendTextCased(text:String)
	{
		var charCount = group.countLiving();
		var xPos:Float = 0;
		var yPos:Float = 0;
		// `countLiving` returns -1 if group is empty
		if (charCount == -1)
			charCount = 0;
		else if (charCount > 0)
		{
			var lastChar = group.members[charCount - 1];
			xPos = lastChar.x + lastChar.width - x;
			yPos = lastChar.y + lastChar.height - maxHeight - y;
		}
		
		var splitValues = text.split("");
		for (i in 0...splitValues.length)
		{
			switch(splitValues[i])
			{
				case " ":
				{
					xPos += 40;
				}
				case "\n":
				{
					xPos = 0;
					yPos += maxHeight;
				}
				case char:
				{
					var charSprite:AtlasChar;
					if (group.members.length <= charCount)
						charSprite = new AtlasChar(atlas, char);
					else
					{
						charSprite = group.members[charCount];
						charSprite.revive();
						charSprite.char = char;
						charSprite.alpha = 1;//gets multiplied when added
					}
					charSprite.x = xPos;
					charSprite.y = yPos + maxHeight - charSprite.height;
					add(charSprite);
					
					xPos += charSprite.width;
					charCount++;
				}
			}
		}
	}
	
	override function toString()
	{
		return "InputItem, " + FlxStringUtil.getDebugString(
			[ LabelValuePair.weak("x", x)
			, LabelValuePair.weak("y", y)
			, LabelValuePair.weak("text", text)
			]
		);
	}
}
