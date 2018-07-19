package interpret;

import interpret.Types;

using StringTools;

class ResolveUsings {

    var usings:Array<TUsing> = [];

    var env:Env;

    var addedItems:Map<String,Map<String,RuntimeItem>> = new Map();

    public function new(env:Env) {

        this.env = env;

    } //new

    public function addUsing(data:TUsing) {

        var parts = data.path.split('.');
        var resolvedModule:DynamicModule = null;
        var i = parts.length;
        var modulePath = data.path;
        while (i > 0) {
            modulePath = parts.slice(0, i).join('.');
            if (env.modules.exists(modulePath)) {
                resolvedModule = env.modules.get(modulePath);
                break;
            }
            i--;
        }

        if (resolvedModule == null) {
            throw 'Module not found: ' + data.path;
        }

        inline function add(name, extendedType, item) {
            var extendedTypesForName = addedItems.get(name);
            if (extendedTypesForName == null) {
                extendedTypesForName = new Map();
                addedItems.set(name, extendedTypesForName);
            }
            extendedTypesForName.set(extendedType, item);
        }

        var prefix = data.path + '.';
        for (itemPath in resolvedModule.items.keys()) {
            var item:RuntimeItem = resolvedModule.items.get(itemPath);
            switch (item) {
                case ExtensionItem(ClassFieldItem(rawItem, _, _), extendedType):
                    if (itemPath.startsWith(prefix)) {
                        var itemParts = itemPath.split('.');
                        if (itemParts.length == parts.length + 1) {
                            add(itemParts[itemParts.length-1], extendedType, item);
                        }
                    }
                default:
            }
        }

        usings.push(data);

    } //addUsing

    inline public function hasName(name:String) {

        return addedItems.exists(name);

    } //hasName

    public function resolve(extendedType:String, name:String):RuntimeItem {

        var extendedTypesForName = addedItems.get(name);

        if (extendedTypesForName != null) {
            if (extendedTypesForName.exists(extendedType)) {
                return extendedTypesForName.get(extendedType);
            }
            var alias = env.aliases.get(extendedType);
            if (alias != null && extendedTypesForName.exists(alias)) {
                return extendedTypesForName.get(alias);
            }
        }

        return null;

    } //resolve

} //ResolveUsings
