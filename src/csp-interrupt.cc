/*----------------------------------------------------------------------
 *
 *  Copyright (C) 2007 Douglas Creager
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later
 *    version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free
 *    Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 *    MA 02111-1307 USA
 *
 *----------------------------------------------------------------------
 */

#ifndef HST_CSP_INTERRUPT_CC
#define HST_CSP_INTERRUPT_CC

#include <iostream>

#include <hst/types.hh>
#include <hst/lts.hh>
#include <hst/csp.hh>
#include <hst/csp-macros.hh>

using namespace std;

namespace hst
{
    void csp_t::interrupt(state_t dest,
                          state_t P, state_t Q)
    {
#if HST_CSP_DEBUG
        cerr << "Interrupt " << dest
             << " = " << P << " /\\ " << Q << endl;
#endif

        /*
         * ‘dest’ shouldn't be finalized, since this implies that it
         * already represents a different process.  ‘P’ and ‘Q’ should
         * be finalized, since we need their initial events to
         * calculate [P▵Q].
         */

        REQUIRE_NOT_FINALIZED(dest);
        REQUIRE_FINALIZED(P);
        REQUIRE_FINALIZED(Q);

        /*
         * Interrupt's ‘P’ operand behaves just like it would in
         * external choice.  Two firing rules are of the form
         *
         *   P =E=> P' ⇒ something
         *
         * We add the appropriate transitions by walking through each
         * (E,P') pair from ‘P’.  The consequent is different
         * depending on whether the event is a τ or not.
         */

        lts_t::state_pairs_iterator  sp_it;

        /*
         * First walk through P's outgoing edges.
         */

        for (sp_it = _lts.state_pairs_begin(P);
             sp_it != _lts.state_pairs_end(P); ++sp_it)
        {
            event_t  E       = sp_it->first;
            state_t  P_prime = sp_it->second;

            if (E == _tau)
            {
                /*
                 * If the event is a τ, then it does *not* resolve the
                 * choice; P' is available, but so is Q.  This means
                 * we need to create a transition for
                 *
                 *   P ▵ Q =τ=> P' ▵ Q
                 */

                state_t  P_prime_interrupt_Q = add_temp_process();
                interrupt(P_prime_interrupt_Q, P_prime, Q);
                _lts.add_edge(dest, E, P_prime_interrupt_Q);
            } else {
                /*
                 * If the event is not τ, then it resolves the choice;
                 * the alternative is no longer available.  We need to
                 * create a transition for
                 *
                 *   P ▵ Q =E=> P'
                 */

                _lts.add_edge(dest, E, P_prime);
            }
        }

        /*
         * Interrupt's ‘Q’ operand is more like internal choice, so we
         * only need a single τ action.
         */

        _lts.add_edge(dest, _tau, Q);

        /*
         * Lastly, finalize the ‘dest’ process.
         */

        _lts.finalize(dest);
    }
}

#endif // HST_CSP_INTERRUPT_CC
