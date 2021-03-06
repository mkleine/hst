/*----------------------------------------------------------------------
 *
 *  Copyright © 2007, 2008 Douglas Creager
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

#include <hst/types.hh>
#include <hst/lts.hh>
#include <hst/normalized-lts.hh>

using namespace std;
using namespace hst;

int main()
{
    lts_t             lts;
    normalized_lts_t  normalized(&lts, 0, FAILURES_DIVERGENCES);
    state_t           source;

    cin >> lts;
    if (cin.fail())
        return 1;

    cin >> source;
    while (!cin.fail())
    {
        state_t  prenormal;

        prenormal = normalized.prenormalize(source);
        cout << normalized;

        cin >> source;
    }
}
