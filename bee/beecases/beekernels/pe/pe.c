// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/types.h>
#include <linux/err.h>
#include <linux/kallsyms.h>

#include <munit.h>

static int pe_0(void)
{
	int a;
	a = 1 + 1;

	LOG_INFO("run pe_0 test!\n");
	MUNIT_EXPECT_EQ(a, 2);
}

static int pe_1(void)
{
	int a;
	a = 1 + 2;

	LOG_INFO("run pe_1 test!\n");
	MUNIT_EXPECT_EQ(a, 3);
}

static int pe_2(void)
{
	int a;
	a = 1 + 3;

	LOG_INFO("run pe_2 test!\n");
	MUNIT_EXPECT_EQ(a, 4);
}

static int pe_3(void)
{
	int a;
	a = 1 + 4;

	LOG_INFO("run pe_3 test!\n");
	MUNIT_EXPECT_EQ(a, 5);
}

static struct munit_case test_cases[] = {
	MUNIT_CASE(pe_0),
	MUNIT_CASE(pe_1),
	MUNIT_CASE(pe_2),
	MUNIT_CASE(pe_3),
	{}
};

static int munit_init(void)
{
	LOG_INFO("pe check setup init succ\n");
	return 0;
}

MUNIT_CASE_INIT("pe", test_cases, munit_init);
MODULE_LICENSE("GPL");

