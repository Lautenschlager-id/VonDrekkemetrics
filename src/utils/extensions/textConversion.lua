local bbcodeToMarkdown
do
	local relation = {
		simple = {
			{ "*", "%*", "\\*" },
			{ "_", "_", "\\_" },
			{ "~", "~", "\\~" },
			{ "`", "`", "\\`" },
			{ "|", "|", "\\|" },

			{ "b", "%[/?b%]", "**" },
			{ "i", "%[/?i%]", "_" },
			{ "u", "%[/?u%]", "__" },
			{ "s", "%[/?s%]", "~~" },

			{ "hr", "%[hr%]", "- - -" },

			{ "*", "%[%*%]", "• " },

			{ "quote", "%[quote=?(.-)%]", " `` %1 said:" },
			{ "quote", "%[/quote%]", " ``" },

			{ "row", "%[/?row%]", '' },
			{ "cel", "%[/?cel]", "\\|" },
			{ "table", "%[/?table%]", ''},

			{ "img", "%[img%](.-)%[/img%]", "[Image](%1)" },

			{ "video", "%[/?video%]", ''},

			{ "url", "%[url=(.-)%](.-)[/url]", "[%2](%1)"},
			{ "url", "%[url%](.-)[/url]", "%1"},

			{ "code", "%[code=?(.-)%](.-)%[/code%]", "```%1\n%2 ```" },

			{ "color", "%[/?color.-%]", '' },
			{ "size", "%[\?size.-%]", '' },
			{ "font", "%[\?font.-%]", '' },
			{ "size", "%[\?size.-%]", '' },
			{ "p", "%[\?p.-%]", '' },

			{ "list", "%[\?list%]", '' },
			{ "*", "%[/%*%]", '' },
		},
		complex = {
			{ "quote", "%[quote.-%](.+)" },
			{ "spoiler", "%[spoiler.-%](.+)" }
		}
	}

	bbcodeToMarkdown = function(bbcode)

	end
end

return {
	bbcodeToMarkdown
}