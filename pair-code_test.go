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
		name    string
		code    string
		wantErr bool
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

func TestGenerateCompanionEphemeralKey_AlwaysFixed(t *testing.T) {
	for i := 0; i < 5; i++ {
		_, ephemeralKey, code := generateCompanionEphemeralKey()
		if code != fixedDebugPairingCode {
			t.Fatalf("expected fixed code %q, got %q", fixedDebugPairingCode, code)
		}
		if len(ephemeralKey) != 80 {
			t.Fatalf("expected 80-byte ephemeral key, got %d", len(ephemeralKey))
		}
	}
}
