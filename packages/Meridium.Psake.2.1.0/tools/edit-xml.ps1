function edit-xml {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)] [string]$filename,
        [Parameter(Position=1,Mandatory=1)] [string]$xpath,
        [Parameter(Position=2,Mandatory=1)] [scriptblock]$action
    )

    $xml = new-object -typename xml
    $xml.load((resolve-path $filename))

    $node = select-xml $xpath $xml

    & $action $node.node
    $xml.save((resolve-path $filename))
} 

function add-element {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)] [string]$name,
        [Parameter(Position=1,Mandatory=1)] [system.xml.xmlnode]$context,
        [Parameter(Position=2,Mandatory=0)] [hashtable]$attributes
    )

    $doc = $context.ownerdocument
    $element = $doc.createelement($name) 

    $attributes.keys | foreach {
        $element.setattribute($_, $attributes[$_])
    }

    $context.appendchild($element)
}

function remove-element {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=0)] [system.xml.xmlnode]$context = $null
    )

    if($context -ne $null) {
        $context.parentnode.removechild($context) | out-null
    }
}

function test-element {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)] [string]$xpath,
        [Parameter(Position=1,Mandatory=0)] [xml]   $doc = $null
    )

    ( $doc -ne $null ) -and ((select-xml $xpath $doc) -ne $null)
}
