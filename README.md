# Franug-TagsSelector

### Installation

- Add a entry on databases.cfg called "franug_tagsselector"
- Drop the smx to plugins folder.
- Create the file "addons/sourcemod/configs/tagsselector_blacklist.txt" and put here the disallowed words (one per line).

### Required: 

- https://github.com/Drixevel/Chat-Processor

### Commands:

- sm_setmyclantag
- sm_setmychattag
- sm_setmycolorchattag
- sm_removemyclantag
- sm_removemychattag

### Cvar (put in server.cfg):

- sm_tagselector_flag "a" // admin flag required for use the features. Leave in blank for public access
