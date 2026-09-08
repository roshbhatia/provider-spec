// Package provider is the canonical provider/v1 contract.
//
// A provider is an ordinary executable described by a manifest. A caller
// writes one request frame to the provider's standard input and reads event
// frames followed by one result frame from its standard output. Payloads
// (request input, event data, result output) are opaque here; each consuming
// tool defines its own.
//
// Every struct is closed. Regenerate schema/ with `nix run .#export`.
@experiment(explicitopen)

package provider

import "strings"

// Duration is the one duration grammar for the contract. It is a strict
// subset of Go's time.ParseDuration: one or more unsigned decimal numbers,
// each followed by a unit. No sign, no bare number, no leading or trailing
// dot, no whitespace.
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// Name is the grammar for provider names, action names, and kinds.
#Name: string & =~"^[a-z][a-z0-9._-]*$"

// EnvName is a POSIX environment variable name.
#EnvName: string & =~"^[A-Za-z_][A-Za-z0-9_]*$"

// ModelID is an opaque model identifier. The role words that a caller uses to
// select a model are not valid identifiers.
#ModelID: string & strings.MinRunes(1) & !="default" & !="light"

// Manifest describes one provider and the actions it implements.
#Manifest: {
	version!: "provider/v1"
	// kind is an opaque classification. A consuming tool may narrow it to its
	// own closed set by unification.
	kind?:        #Name
	name!:        #Name
	description!: string & strings.MinRunes(1)
	// command is the executable and its fixed leading arguments. It always
	// runs directly; no shell is inserted.
	command!: [string & strings.MinRunes(1), ...string & strings.MinRunes(1)]
	actions!: [=~"^[a-z][a-z0-9._-]*$"]: #Action
	requires?: #Requirements
	defaults?: #Defaults
}

// Action describes one capability and its action-specific arguments and
// environment. Each argv and env value is a template the caller renders.
#Action: {
	description!: string & strings.MinRunes(1)
	argv?: [...string]
	env?: [=~"^[A-Za-z_][A-Za-z0-9_]*$"]: string
}

// Requirements declares dependencies which must exist before invocation.
#Requirements: {
	commands?: [...string & strings.MinRunes(1)]
	environment?: [...#EnvName]
	paths?: [...string & strings.MinRunes(1)]
}

// Defaults carries provider-wide execution policy. model is what a plain
// request runs; light is the cheap model for bulk work.
#Defaults: {
	timeout?:  #Duration
	priority?: int
	model?:    #ModelID
	light?:    #ModelID
}

// Request is the single frame a caller writes to provider standard input.
#Request: {
	version!:    "provider/v1"
	kind!:       "request"
	requestId!:  string & strings.MinRunes(1)
	capability!: string & strings.MinRunes(1)
	operation?:  string
	context?: [string]: _
	input?: _
}

// Event is a streaming frame a provider emits before the final result.
#Event: {
	version!:   "provider/v1"
	kind!:      "event"
	requestId!: string & strings.MinRunes(1)
	event!:     string & strings.MinRunes(1)
	message?:   string
	data?:      _
}

// Result is the final frame a provider emits.
#Result: {
	version!:   "provider/v1"
	kind!:      "result"
	requestId!: string & strings.MinRunes(1)
	status!:    "ok" | "declined" | "error"
	output?:    _
	message?:   string
	metadata?: [string]: string
}
