<?php

if (!isset($argv[1])) {
	
	echo "\n\tusage: php {$argv[0]} PREFIX\n";
	echo "\n";
	echo "\tPREFIX would be added to all RDHTTP classes / global vars / types,\n";
	echo "\tto emulate namespaces in Objective-C.\n\n";
	echo "\tUsually two or three-letter prefixes are sufficient.\n";
	echo "\tPrefixes are always capitalized.\n\n";
	echo "\tPREFIXRDHTTP.h and PREFIXRDHTTP.m would be generated in scripts directory.\n";
	echo "\n";
	exit;
}

$prefix = strtoupper(trim($argv[1]));

if (strlen($prefix) < 2)
	die("1-letter prefix are not recommented.\n");

$in_dir = dirname(__FILE__).'/RDHTTP/';
$out_dir = dirname(__FILE__).'/';

$files = array('RDHTTP.h', 'RDHTTP.m');

foreach($files as $file) {
	$contents = file_get_contents($in_dir.$file);
	$contents = rdhttp_apply_namespace($contents, $prefix);
	file_put_contents($out_dir.$prefix.$file, $contents);
}

function rdhttp_apply_namespace($contents, $prefix) {
	$rd_globals = array('RDHTTPResponseCodeErrorDomain');
					
	$rd_block_types = array('rdhttp_block_t', 'rdhttp_header_block_t', 'rdhttp_progress_block_t',
							'rdhttp_trustssl_block_t', 'rdhttp_httpauth_block_t');
	
	$rd_categories = array('RDHTTPPrivate');
	
	$rd_classes = array('RDHTTPFormPost', 'RDHTTPOperation', 'RDHTTPResponse', 'RDHTTPChallangeDecision', 
						'RDHTTPAuthorizer', 'RDHTTPSSLServerTrust', 'RDHTTPRequest', 
						'RDHTTPMultipartPostStream', 'RDHTTPThread');
						
	
	
	$replaces_from = array_merge($rd_globals, $rd_block_types, $rd_categories);
	$replaces_to = array();
	foreach($replaces_from as $replace) {
		$local_prefix = $prefix;
		if (substr($replace, 0, 1) == 'r')
			$local_prefix = strtolower($prefix);
		
		array_push($replaces_to, $local_prefix.$replace); 
	}
	
	$contents = str_replace($replaces_from, $replaces_to, $contents);
	
	foreach($rd_classes as $replace) {
		$contents = preg_replace("|{$replace}(\s+)\*|", "{$prefix}{$replace}\\1*", $contents); // vars
		$contents = str_replace("[{$replace} ", "[{$prefix}{$replace} ", $contents); // class methods
		$contents = str_replace("@class {$replace}", "@class {$prefix}{$replace}", $contents); // forward decl
		$contents = str_replace("@interface {$replace}", "@interface {$prefix}{$replace}", $contents); // interface
		$contents = str_replace(" : {$replace}", " : {$prefix}{$replace}", $contents); // inheritance
		
		$contents = str_replace("@implementation {$replace}", "@implementation {$prefix}{$replace}", $contents); // implementation
	}
	
	$contents = str_replace("#import \"RDHTTP.h\"", "#import \"{$prefix}RDHTTP.h\"", $contents); // #import
	
	return $contents;
}

