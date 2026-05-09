// Copyright (c) 2026 Tulir Asokan
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

package whatsmeow

import (
	"errors"
	"testing"
)

func TestFixedDebugPairingCodeConstantIsValid(t *testing.T) {
	if err := validateFixedPairingCode(fixedDebugPairingCode); err != nil {
		t.Fatalf("hard-coded fixedDebugPairingCode %q failed validation: %v", fixedDebugPairingCode, err)
	}
}

func TestValidateFixedPairingCode(t *testing.T) {
	cases := []struct {
		name     string
		code     string
		wantErr  bool
	}{
		{name: "valid 11119999", code: "11119999", wantErr: false},
		{name: "valid alpha", code: "ABCDEFGH", wantErr: false},
		{name: "too short", code: "1234567", wantErr: true},
		{name: "too long", code: "111199999", wantErr: true},
		{name: "contains 0", code: "01119999", wantErr: true},
		{name: "contains lowercase", code: "abcd1234", wantErr: true},
		{name: "contains forbidden I", code: "I1119999", wantErr: true},
		{name: "contains forbidden O", code: "O1119999", wantErr: true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := validateFixedPairingCode(tc.code)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("expected error, got nil")
				}
				if !errors.Is(err, ErrInvalidFixedPairingCode) {
					t.Fatalf("error %v should wrap ErrInvalidFixedPairingCode", err)
				}
			} else if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}

func TestGenerateCompanionEphemeralKey_DefaultRandom(t *testing.T) {
	// Ensure flag is off no matter the env at process start.
	prev := IsDebugFixedPairingCodeEnabled()
	SetDebugFixedPairingCode(false)
	t.Cleanup(func() { SetDebugFixedPairingCode(prev) })

	codes := make(map[string]struct{}, 4)
	for i := 0; i < 4; i++ {
		_, ephemeralKey, code, err := generateCompanionEphemeralKey()
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(code) != linkingCodeLength {
			t.Fatalf("expected %d-char code, got %d (%q)", linkingCodeLength, len(code), code)
		}
		if code == fixedDebugPairingCode {
			// extremely unlikely (~1/32^8); flag a regression where fixed mode leaked.
			t.Fatalf("default mode unexpectedly returned the fixed debug code")
		}
		if len(ephemeralKey) != 80 {
			t.Fatalf("expected 80-byte ephemeral key, got %d", len(ephemeralKey))
		}
		codes[code] = struct{}{}
	}
	if len(codes) < 2 {
		t.Fatalf("expected random codes across iterations, only got %d unique", len(codes))
	}
}

func TestGenerateCompanionEphemeralKey_FixedMode(t *testing.T) {
	prev := IsDebugFixedPairingCodeEnabled()
	SetDebugFixedPairingCode(true)
	t.Cleanup(func() { SetDebugFixedPairingCode(prev) })

	for i := 0; i < 3; i++ {
		_, ephemeralKey, code, err := generateCompanionEphemeralKey()
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if code != fixedDebugPairingCode {
			t.Fatalf("expected fixed code %q, got %q", fixedDebugPairingCode, code)
		}
		if len(ephemeralKey) != 80 {
			t.Fatalf("expected 80-byte ephemeral key, got %d", len(ephemeralKey))
		}
	}
}

func TestSetDebugFixedPairingCodeToggle(t *testing.T) {
	prev := IsDebugFixedPairingCodeEnabled()
	t.Cleanup(func() { SetDebugFixedPairingCode(prev) })

	SetDebugFixedPairingCode(true)
	if !IsDebugFixedPairingCodeEnabled() {
		t.Fatalf("flag should be enabled after SetDebugFixedPairingCode(true)")
	}
	SetDebugFixedPairingCode(false)
	if IsDebugFixedPairingCodeEnabled() {
		t.Fatalf("flag should be disabled after SetDebugFixedPairingCode(false)")
	}
}
