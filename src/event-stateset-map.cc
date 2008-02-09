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

#ifndef EVENT_STATESET_MAP_CC
#define EVENT_STATESET_MAP_CC

#include <hst/types.hh>
#include <hst/event-stateset-map.hh>

using namespace std;

#ifndef MAP_DEBUG
#define MAP_DEBUG 0
#endif

namespace hst
{
    stateset_p event_stateset_map_t::get(event_t event)
    {
        stateset_p  stateset;
        pair<map_t::iterator, bool>  insert_result;

        // Try to insert a NULL stateset into the map.  This will tell
        // us whether there's already a stateset for this event.

        insert_result = map.insert(make_pair(event, stateset));

        if (insert_result.second)
        {
            // The insert succeeded, so there's currently a NULL
            // pointer in the map for this event.  We need to change
            // this NULL to a pointer to an actual stateset; luckily,
            // we've got an iterator we can use to do this, though
            // it's a bit tricky.

            insert_result.first->second.reset(new stateset_t);
        } else {
            // The insert failed because there's already a
            // stateset.  Moreover, the iterator points to the
            // stateset's smart_ptr, so there's not really
            // anything to do here.
        }

        return insert_result.first->second;
    }

    stateset_cp event_stateset_map_t::get(event_t event) const
    {
        map_t::const_iterator  it = map.find(event);

        if (it == map.end())
        {
            return stateset_cp();
        } else {
            return it->second;
        }
    }
}

#endif // EVENT_STATESET_MAP_CC